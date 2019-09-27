function testcall(userinput; verbose=true)
    if userinput == "t(1)"
        abstractlogic("clear")
        abstractlogic("a,b,c ∈ 1:4")
        abstractlogic("a|c = 1")
        abstractlogic("a > b")
        abstractlogic("b > c")
        return
    elseif userinput == "t(hp)"
        abstractlogic("clear")
        abstractlogic("a, b, c, d, e, f, g  ∈  NW, MA, MB, PO")
        abstractlogic("{{i}} == 'NW' {{2}}")
        abstractlogic("{{i}} == 'MA' {{1}}")
        abstractlogic("{{i}} == 'MB' {{1}}")
        abstractlogic("{{i}} == 'PO' {{3}}")
        abstractlogic("{{i!}} == 'NW' ==> {{i-1}} == 'PO'")
        abstractlogic("a != g")
        abstractlogic("a,g != 'MA'")
        abstractlogic("c,f != 'PO'")
        abstractlogic("b == f")
        return
    end
    replthrow("$userinput - test not found!")
    return
end