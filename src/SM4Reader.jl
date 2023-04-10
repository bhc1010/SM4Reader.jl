##! 
##!
##!
##!
##!
##!
##!
##!
##!

module SM4Reader

export parse

using Match

include("./format.jl")
include("./utils.jl")

@enum DataSource begin
    image = 1
    specImage = 2
    pllImage = 3
    lineSpec = 16
    ptSpec = 38
end

"""
    readsm4(io::IO)
"""
function readsm4(io::IO)
    ###------- Skip header (We never use it) ----------
    #--------------------------------------------------
    skip!(io, 21, Int16)
    objListCount = fread(io, 1, Int32)
    skip!(io, 3, Int32)

    ## Skip Header Objects
    skip!(io, 3 * objListCount, Int32)

    ## Read page count
    pageCount = fread(io, 1, Int32)

    ## Intialize empty FileData
    raw = FileData(pageCount)

    ## Skip useless page header information (Object List Count, Reserved, ObjectID, Offset, Size)
    skip!(io, 6, Int32)

    ###--------- Get offset and size of data for each page -----------
    for page ∈ raw.pages
        # Skip useless page information
        skip!(io, 6, Int32)

        # Read page object list count
        page.objListCount = fread(io, 1, UInt32)

        ## Skip minor version info
        skip!(io, 1, Int32)

        ## Read offset and size of header and data for each page
        for _ ∈ 1:page.objListCount
            objID = fread(io, 1, UInt32)
            id = ObjectIDCode[(objID % length(ObjectIDCode)) + 1]
            if id == "Page Header"
                page.header.offset = fread(io, 1, Int32)
                page.header.size = fread(io, 1, Int32)
            elseif id == "Page Data"
                page.data.offset = fread(io, 1, Int32)
                page.data.size = fread(io, 1, Int32)
            else
                skip!(io, 2, Int32)
            end
        end
    end 
    
    ###--------- Iterate through pages, read header, text, and measurements ----------
    for page ∈ raw.pages
        # Seek start of header 
        seek(io, page.header.offset)

        ########### TODO: automate this 
        #### # Define Order and number of datatypes to read
        #### readOrder = [(2, Int16), (13, Int32), (11, Float32), (4, Int32)]

        #### # Read header
        #### cumsum = readOrder[1][1]
        #### nextReadOrder = iterate(readOrder)
        #### for (i, field) ∈ enumerate(fieldnames(typeof(page.header)))
        ####     ((j, type), state) = nextReadOrder
        ####     if i > cumsum
        ####         nextReadOrder = iterate(readOrder, state)
        ####         ((j, type), state) = nextReadOrder
        ####         cumsum += j
        ####     end

        ####     setfield!(page.header, field, fread(io, 1, type))
        #### end

        page.header.fieldSize = fread(io, 1, Int16)
        page.header.stringCount = fread(io, 1, Int16)
        page.header.pageTypeDatasource = fread(io, 1, Int32)
        page.header.dataSubsource = fread(io, 1, Int32)
        page.header.lineType = fread(io, 1, Int32)
        page.header.corner.x = fread(io, 1, Int32)
        page.header.corner.y = fread(io, 1, Int32)
        page.header.width = fread(io, 1, Int32)
        page.header.height = fread(io, 1, Int32)
        page.header.imageType = fread(io, 1, Int32)
        page.header.scanDirection = fread(io, 1, Int32)
        page.header.groupId = fread(io, 1, Int32)
        page.header.pageDataSize = fread(io, 1, Int32)
        page.header.minZValue = fread(io, 1, Int32)
        page.header.maxZValue = fread(io, 1, Int32)
        page.header.scale.x = fread(io, 1, Float32)
        page.header.scale.y = fread(io, 1, Float32)
        page.header.scale.z = fread(io, 1, Float32)
        page.header.xyScale = fread(io, 1, Float32)
        page.header.xyzOffset.x = fread(io, 1, Float32)
        page.header.xyzOffset.y = fread(io, 1, Float32)
        page.header.xyzOffset.z = fread(io, 1, Float32)
        page.header.period = fread(io, 1, Float32)
        page.header.bias = fread(io, 1, Float32)
        page.header.current = fread(io, 1, Float32)
        page.header.angle = fread(io, 1, Float32)
        page.header.colorInfoListCount = fread(io, 1, Int32)
        page.header.gridSize.x = fread(io, 1, Int32)
        page.header.gridSize.y = fread(io, 1, Int32)
        page.header.objectListCount = fread(io, 1, Int32)

        # Skip flags and reserved data
        skip(io, 64)

        for j ∈ 1:page.header.objectListCount
            push!(page.header.objectList, PageHeaderObject())
            page.header.objectList[j].id = fread(io, 1, Int32)
            page.header.objectList[j].offset = fread(io, 1, Int32)
            page.header.objectList[j].size = fread(io, 1, Int32)
        end

        # Read page info
        for field in fieldnames(PageInfo)
            size = fread(io, 1, Int16)
            str = fread(io, Int64(size) / 2, Char)
            str = replace(str, r"\0"=>"")
            setfield!(page.info, field, str)
        end

        # Read raw data
        seek(io, page.data.offset)
        dims = Int(page.data.size / sizeof(Int32))
        page.data.raw = fread_to_array(io, dims, Int32)
        
        # Scale raw data 
        zScale = page.header.scale.z 
        zOffset = page.header.xyzOffset.z
        scaledData = (zScale * page.data.raw) .+ zOffset
        width = page.header.width
        height = page.header.height
        page.data.scaled = reshape(scaledData, width, height)

    end # end page

    return raw
end

function freadSpectralInfo(io::IO, page::Page, offset::Int)
    seek(io, offset)
    page
end

"""
"""
function formatsm4(io::IO, raw::FileData)
    sm4 = SM4Data()

    for page in raw.pages
        dataSrc = DataSource(page.header.pageTypeDatasource)
        @match page.info.label begin
        ## Topography
            "Topography" => pushSpatialInfo!(sm4, page, :topography)
        ## Current
            "Current"   => begin
                if dataSrc == specImage
                    pushSpatialInfo!(sm4, page, :IVMap)
                elseif dataSrc == ptSpec
                    pushSpectralInfo!(io, sm4, page, :IVPoint)
                elseif dataSrc == lineSpec
                    pushSpectralInfo!(io, sm4, page, :IVLine)
                end     
            end
        ## LIA Current
            "LIA Current"   => begin
                if dataSrc == specImage
                    pushSpatialInfo!(sm4, page, :dIdVMap)
                elseif dataSrc == ptSpec
                    pushSpectralInfo!(io, sm4, page, :dIdVPoint)
                elseif dataSrc == lineSpec
                    pushSpectralInfo!(io, sm4, page, :dIdVLine)
                end     
            end
        ## PLL Amplitude
            "PLL Amplitude" => begin
                if dataSrc == specImage    
                    pushSpatialInfo!(sm4, page, :pllAmplitude)
                elseif dataSrc == ptSpec
                    pushSpectralInfo!(io, sm4, page, :pllAmplitudeSpec)
                end
            end
        ## PLL Phase
            "PLL Drive" => begin
                if dataSrc == specImage    
                    pushSpatialInfo!(sm4, page, :pllDrive)
                elseif dataSrc == ptSpec
                    pushSpectralInfo!(io, sm4, page, :pllDriveSpec)
                end
            end
        ## PLL Drive
            "PLL Phase" => begin
                if dataSrc == specImage    
                    pushSpatialInfo!(sm4, page, :pllPhase)
                elseif dataSrc == ptSpec
                    pushSpectralInfo!(io, sm4, page, :pllPhaseSpec)
                end
            end
        end
    end

    return sm4
end

"""
"""
function pushSpatialInfo!(sm4::SM4Data, page::Page, field::Symbol)
    units = Symbol(String(field) * "Units")

    push!(getfield(sm4.spatial, field), page.data.scaled)
    setfield!(sm4.spatial, units, page.info.zUnits)

    sm4.spatial.points = page.header.width
    sm4.spatial.lines = page.header.height
    sm4.spatial.width = abs(page.header.scale.x * sm4.spatial.points)
    sm4.spatial.height = abs(page.header.scale.y * sm4.spatial.lines)
    sm4.spatial.rectUnits = "m"

    sm4.spatial.bias = page.header.bias
    sm4.spatial.biasUnits = "V"
    
    sm4.spatial.current = page.header.current
    sm4.spatial.currentUnits = "A"

    sm4.spatial.xOffset = page.header.xyzOffset.x
    sm4.spatial.yOffset = page.header.xyzOffset.y
    sm4.spatial.offsetUnits = "m"
end

"""
"""
function pushSpectralInfo!(io::IO, sm4::SM4Data, page::Page, field::Symbol, units = nothing)
    isnothing(units) && (units = Symbol(String(field) * "Units"))

    push!(getfield(sm4.spectral, field), page.data.scaled)
    setfield!(sm4.spectral, units, page.info.zUnits)

    sm4.spectral.points = page.header.width
    sm4.spectral.scans = page.header.height

    sm4.spectral.bias = page.header.bias
    sm4.spectral.biasUnits = "V"

    sm4.spectral.current = page.header.current
    sm4.spectral.currentUnits = "A"

    voltageLinSpace = collect(1:sm4.spectral.points) .- 1
    sm4.spectral.xData = page.header.xyzOffset.x .+ page.header.scale.x * voltageLinSpace
    sm4.spectral.xDataUnits = page.info.xUnits
 
    if any(occursin.(["Line", "Point"], String(field)))
        offset = filter(x -> x.id == 8, page.header.objectList)[1].offset
        seek(io, offset)
        for _ ∈ 1:sm4.spectral.scans
            sm4.spectral.startTime = fread(io, 1, Float32)

            xCoord = fread(io, 1, Float32)
            yCoord = fread(io, 1, Float32)
            push!(sm4.spectral.coords, Vector2{Float64}(xCoord, yCoord))
            sm4.spectral.coordsUnits = "m"

            sm4.spectral.steps.x = fread(io, 1, Float32)
            sm4.spectral.steps.y = fread(io, 1, Float32)

            sm4.spectral.cumulative.x = fread(io, 1, Float32)
            sm4.spectral.cumulative.y = fread(io, 1, Float32)

            sm4.spectral.type = split(String(field), "V")[2]
        end
    end
end

"""
"""
function parse(file::String)
    # open file
    io = open(file)

    # Read raw binary data
    raw = readsm4(io)
    
    # Format data into spatial, spectral, and PLL
    sm4 = formatsm4(io, raw)

    # close file
    close(io)

    return (raw, sm4)
end

end # module sm4reader