using YAML

function readconfig(ymlpath)
    if ymlpath[1:11] == "../configs/"
        ymlpath = joinpath(dirname(@__FILE__), "../" * ymlpath)
    end

    YAML.load(open(ymlpath))
end

function parsemonth(mmyyyy)
    parts = split(mmyyyy, '/')
    (parse(UInt16, parts[2]) - 1) * 12 + parse(UInt8, parts[1])
end
