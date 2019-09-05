"""
    x,y,z ∈ 1,2,3
    x,y,z ∈ 1:3
    x,y,z ∈ apples, oranges, grapes
"""
function operatoreval(command, logicset::LogicalCombo; verbose=true)
    logicsetcopy = deepcopy(logicset)

    #println("operatoreval($command)")
    (sum(logicset[:]) == 0) && return logicset
    occursin(r"\{\{.*\}\}", command) &&
      return operatorspawn(command, logicset, verbose=verbose)

    n = 1:sum(logicset[:])

    # convert a = b|c to a |= b,c
    if occursin("|", command) & occursin(r"(\b| )[!|]*=+[!|]*(\b| )", command)
      command = replace(command, "|"=>",")
      command = replace(command, r",*=+"=>"|=")
    end

    command = replace(command, r"^(.*?)[ ]*([!&])[ ]*$"=>s"\1 \2 \1")
    command = replace(command, r"^[ ]*([!&])[ ]*(.*?)$"=>s"\2 \1 \2")

    m = match(r"^(.*?)(([><=|!^&]{1,3}))(.*?)(\{([0-9]+),?([0-9]+)*\})?$",command)
    left, right, operator, nmin, nmax  = m.captures[[1,4,3,6,7]]

    (nmin === nothing)  && (nmax === nothing)  && (nrange = 1:999)
    !(nmin === nothing) && (nmax === nothing)  && (nrange = integer(nmin):integer(nmin))
    !(nmin === nothing) && !(nmax === nothing) && (nrange = integer(nmin):integer(nmax))

    leftarg  = strip.(split(left,  r"[,&|!]"))
    rightarg = strip.(split(right, r"[,&|!]"))

    leftvals  = hcat([grab(L, logicset, command=command) for L in leftarg]...)
    rightvals = hcat([grab(R, logicset, command=command) for R in rightarg]...)

    if operator == ""
        throw("No operator found!")

    elseif operator == "|"
        lcheck = [any(isodd.(leftvals[i,:])) for i in n]
        rcheck = [any(isodd.(rightvals[i,:])) for i in n]
        ℧Δ = [all(lcheck[i,:]) | all(rcheck[i,:]) for i in n]

    elseif operator == "&"
        lcheck = [all(isodd.(leftvals[i,:])) for i in n]
        rcheck = [all(isodd.(rightvals[i,:])) for i in n]
        ℧Δ = [all(lcheck[i,:]) & all(rcheck[i,:]) for i in n]

    elseif operator == "^"
        ℧Δ = (isodd.(leftvals[:,1]) .& iseven.(rightvals[:,1])) .|
             (iseven.(leftvals[:,1]) .& isodd.(rightvals[:,1]))

    elseif operator == "!"
        lcheck = [all(iseven.(leftvals[i,:])) for i in n]
        rcheck = [all(iseven.(rightvals[i,:])) for i in n]
        ℧Δ = [all(lcheck[i,:]) & all(rcheck[i,:]) for i in n]

    elseif operator == "^="
         lcheck = [sum(leftvals[i,j]  .== rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
         rcheck = [sum(rightvals[i,j] .== leftvals[i,:])  for i in n, j in 1:size(rightvals)[2]]
         ℧Δ = [sum(lcheck[i,:]) + sum(rcheck[i,:]) == 2 for i in n]

    elseif operator  ∈ ["==","="]
        lcheck = [all(leftvals[i,j] .== rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]

    elseif operator == "!="
        lcheck = [all(leftvals[i,j] .!= rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]

    elseif operator ∈ ["|=", "=|"]
        lcheck = [any(leftvals[i,j] .== rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [sum(lcheck[i,:]) ∈ nrange for i in n]

    elseif operator ∈ ["|!=", "|!", "!|", "!|=", "=|!", "|=!"]
        lcheck = [any(leftvals[i,j] .!= rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [sum(lcheck[i,:]) ∈ nrange for i in n]

    elseif operator == "<="
        lcheck = [all(leftvals[i,j] .<= rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]

    elseif operator == "<"
        lcheck = [all(leftvals[i,j] .< rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]

    elseif operator == "<<"
        lcheck = [all(leftvals[i,j] .< rightvals[i,:].-1) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]

    elseif operator == ">="
        lcheck = [all(leftvals[i,j] .>= rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]

    elseif operator == ">"
        lcheck = [all(leftvals[i,j] .> rightvals[i,:]) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]

    elseif operator == ">>"
        lcheck = [all(leftvals[i,j] .> rightvals[i,:].+1) for i in n, j in 1:size(leftvals)[2]]
        ℧Δ = [all(lcheck[i,:]) for i in n]
    end

    logicsetcopy.logical[logicsetcopy[:]] = ℧Δ

    logicsetcopy
end

function grab(argument::AbstractString, logicset::LogicalCombo; command = "")

  (argument[1:1]=="'") && return fill(replace(argument, "'"=>""), length(logicset[:]))

  matcher = r"^([a-zA-z][a-zA-z0-9.]*)*([0-9]+)*([+\-*/])*([a-zA-z][a-zA-z0-9]*)*([0-9]+)*$"

  m = match(matcher, argument)
  nvar = 5-sum([i === nothing for i in m.captures])
  (nvar==0) && throw("Argument $argument could not be parsed in $command")

  v1, n1, o1, v2, n2 = m.captures

  !(v1 === nothing) && (left  = logicset[:,Symbol(v1),true])
  !(n1 === nothing) && (left  = fill(integer(n1), length(logicset[:])))

  (nvar==1) && return left

  !(v2 === nothing) && (right = logicset[:,Symbol(v2),true])
  !(n2 === nothing) && (right = fill(integer(n2), length(left)))

  (o1 == "+") && return left .+ right
  (o1 == "-") && return left .- right
  (o1 == "/") && return left ./ right
  (o1 == "*") && return left .* right
end
