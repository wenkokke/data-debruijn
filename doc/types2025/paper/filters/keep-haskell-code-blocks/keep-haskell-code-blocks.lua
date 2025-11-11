return {
    {
        CodeBlock = function (elem)
            if FORMAT:match 'latex' then
                if elem.attr.classes:includes("haskell") then
                    return pandoc.RawBlock("latex", "\\begin{code}\n" .. elem.text .. "\n\\end{code}\n")
                elseif elem.attr.classes:includes("haskellspec") then
                    return pandoc.RawBlock("latex", "\\begin{spec}\n" .. elem.text .. "\n\\end{spec}\n")
                end
            end
        end,
    }
}
