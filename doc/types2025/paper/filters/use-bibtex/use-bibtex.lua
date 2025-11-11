return {
    {
        Cite = function (elem)
            if FORMAT:match 'latex' then
                local content = ""
                for k, citation in pairs(elem.citations) do
                    content = content .. citation.id
                    if k > 1 then
                        content = content .. ","
                    end
                end
                return pandoc.RawInline('latex', '\\cite{' .. content .. '}')
            end
        end,
    }
}
