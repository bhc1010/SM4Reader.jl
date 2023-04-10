Base.@kwdef mutable struct Vector2{T <: Number}
    x::T = zero(T)
    y::T = zero(T)
end

Base.@kwdef mutable struct Vector3{T <: Number}
    x::T = zero(T)
    y::T = zero(T)
    z::T = zero(T)
end

mutable struct PageHeaderObject
    id::Int
    size::Int
    offset::Int

    PageHeaderObject() = new(zero(Int), zero(Int), zero(Int))
end

Base.@kwdef mutable struct PageHeader
    offset::Int = zero(Int)
    size::Int = zero(Int)
    fieldSize::Int = zero(Int)
    stringCount::Int = zero(Int)
    pageTypeDatasource::Int = zero(Int)
    dataSubsource::Int = zero(Int)
    lineType::Int = zero(Int)
    corner::Vector2{Int} = Vector2{Int}()
    width::Int = zero(Int)
    height::Int = zero(Int)
    imageType::Int = zero(Int)
    scanDirection::Int = zero(Int)
    groupId::Int = zero(Int)
    pageDataSize::Int = zero(Int)
    minZValue::Int = zero(Int)
    maxZValue::Int = zero(Int)
    scale::Vector3{Float64} = Vector3{Float64}()
    xyScale::Float64 = zero(Float64)
    xyzOffset::Vector3{Float64} = Vector3{Float64}()
    period::Float64 = zero(Float64)
    bias::Float64 = zero(Float64)
    current::Float64 = zero(Float64)
    angle::Float64 = zero(Float64)
    colorInfoListCount::Int = zero(Int)
    gridSize::Vector2{Int} = Vector2{Int}()
    objectListCount::Int = zero(Int)
    objectList::Array{PageHeaderObject} = []
end

Base.@kwdef mutable struct PageInfo
    label::String = ""
    system::String = ""
    session::String = ""
    user::String = ""
    path::String = ""
    date::String = ""
    time::String = ""
    xUnits::String = ""
    yUnits::String = ""
    zUnits::String = ""
    xLabel::String = ""
    yLabel::String = ""
    statusChannel::String = ""
    completedLineCount::String = ""
    overSamplingCount::String = ""
    slicedVoltage::String = ""
    pplProStatus::String = ""
    setpointUnits::String = ""
    chDriveValues::String = ""
end

Base.@kwdef mutable struct PageData
    size::Int = 0
    offset::Int = 0
    raw::Array{Float64} = []
    scaled::Array{Float64} = []
end

mutable struct Page
    objListCount::Int
    header::PageHeader
    data::PageData
    info::PageInfo

    Page() = new(zero(Int), PageHeader(), PageData(), PageInfo())
end

mutable struct FileData 
    pageCount::Int
    pages::Array{Page}

    function FileData(size::Int32)
        pages = []
        for _ in 1:size
            push!(pages, Page())
        end

        new(size, pages)
    end
end

Base.@kwdef mutable struct SpatialData
    points::Int = zero(Int)
    lines::Int = zero(Int)
    width::Float64 = zero(Float64)
    height::Float64 = zero(Float64)
    rectUnits::String = ""
    count::Int = zero(Int)
    bias::Float64 = zero(Float64)
    biasUnits::String = ""
    current::Float64 = zero(Float64)
    currentUnits::String = "" 
    xOffset::Float64 = zero(Float64) 
    yOffset::Float64 = zero(Float64)
    offsetUnits::String = ""
    topography::Vector{Array{Float64}} = []
    topographyUnits::String = ""
    IVMap::Vector{Array{Float64}} = []
    IVMapUnits::String = ""
    dIdVMap::Vector{Array{Float64}} = []
    dIdVMapUnits::String = "" 
    pllAmplitude::Vector{Array{Float64}} = []
    pllAmplitudeUnits::String = ""
    pllPhase::Vector{Array{Float64}} = []
    pllPhaseUnits::String = ""
    dF::Vector{Array{Float64}} = []
    dFUnits::String = ""
    dFSetpoint::Vector{Array{Float64}} = []
    dFSetpointUnits::String = ""
    pllDrive::Vector{Array{Float64}} = []
    pllDriveUnits::String = ""
end

Base.@kwdef mutable struct SpectralData
    type::String = ""
    points::Int = zero(Int)
    scans::Int = zero(Int)
    count::Int = zero(Int)
    bias::Float64 = zero(Float64)
    biasUnits::String = ""
    current::Float64 = zero(Float64)
    currentUnits::String = ""
    startTime::Float64 = zero(Float64)
    coords::Vector{Vector2{Float64}} = []
    coordsUnits::String = ""
    steps::Vector2{Float64} = Vector2{Float64}()
    cumulative::Vector2{Float64} = Vector2{Float64}()
    xData::Array{Float64} = []
    xDataUnits::String = ""
    dIdVPoint::Vector{Array{Float64}} = []
    dIdVPointUnits::String = ""
    dIdVLine::Vector{Array{Float64}} = []
    dIdVLineUnits::String = ""
    IVPoint::Vector{Array{Float64}} = []
    IVPointUnits::String = ""
    IVLine::Vector{Array{Float64}} = []
    IVLineUnits::String = ""
    pllAmplitude::Vector{Array{Float64}} = []
    pllAmplitudeUnits::String = ""
    pllPhase::Vector{Array{Float64}} = []
    pllPhaseUnits::String = ""
    pllDrive::Vector{Array{Float64}} = []
    pllDriveUnits::String = ""
    pllAmplitudeSpec::Vector{Array{Float64}} = []
    pllAmplitudeSpecUnits::String = ""
    pllPhaseSpec::Vector{Array{Float64}} = []
    pllPhaseSpecUnits::String = ""
    pllDriveSpec::Vector{Array{Float64}} = []
    pllDriveSpecUnits::String = ""
    dF::Vector{Array{Float64}} = []
    dFUnits::String = ""
end

Base.@kwdef mutable struct PLLData
    driveAmplitude::Vector{Array{Float64}} = []
    driveAmplitudeUnits::String = ""
    driveRefFreq::Vector{Array{Float64}} = []
    driveRefFreqUnits::String = ""
    lockinFreqOffset::Vector{Array{Float64}} = []
    lockinFreqOffsetUnits::String = ""
    lockinHarmonicFactor::Vector{Array{Float64}} = []
    lockinPhaseOffset::Vector{Array{Float64}} = []
    lockinPhaseOffsetUnits::String = ""
    piGain::Vector{Array{Float64}} = []
    piGainUnits::String = ""
    pIntCutoffFreq::Vector{Array{Float64}} = []
    pIntCutoffFreqUnits::String = ""
    lowerBound::Vector{Array{Float64}} = []
    upperBound::Vector{Array{Float64}} = []
    piOutputUnits::String = ""
    dissPIGain::Vector{Array{Float64}} = []
    dissPIGainUnits::String = ""
    dissIntCutoffFreq::Vector{Array{Float64}} = []
    dissIntCutoffFreqUnits::String = ""
    dissLowerBound::Vector{Array{Float64}} = []
    dissUpperBound::Vector{Array{Float64}} = []
    dissPIOutputUnits::String = ""
end

struct MemscopeData

end

mutable struct SM4Data
    spatial::SpatialData
    spectral::SpectralData
    pll::PLLData
    memscope::MemscopeData

    SM4Data() = new(SpatialData(), SpectralData(), PLLData(), MemscopeData())
end

ObjectIDCode = hcat(
    "Undefined",
    "Page Index Header",
    "Page Index Array",
    "Page Header",
    "Page Data",
    "Image Drift Header",
    "Image Drift",
    "Spec Drift Header",
    "Spec Drift Data (with X,Y coordinates)",
    "Color Info",
    "String data",
    "Tip Track Header",
    "Tip Track Data",
    "PRM",
    "Thumbnail",
    "PRM Header",
    "Thumbnail Header",
    "API Info",
    "History Info",
    "Piezo Sensitivity",
    "Frequency Sweep Data",
    "Scan Processor Info",
    "PLL Info",
    "CH1 Drive Info",
    "CH2 Drive Info",
    "Lockin0 Info",
    "Lockin1 Info",
    "ZPI Info",
    "KPI Info",
    "Aux PI Info",
    "Low-pass Filter0 Info",
    "Low-pass Filter1 Info"
)