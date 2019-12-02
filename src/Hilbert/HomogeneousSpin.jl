export HomogeneousSpin

mutable struct HomogeneousSpin{D} <: AbstractHilbert
    n_sites::Int
    shape::Vector{Int}
end

function HomogeneousSpin(n_sites, S::Rational=1//2)
    @assert S.den == 2
    N = S.num +1
    return HomogeneousSpin{N}(n_sites, fill(N, n_sites))
end

@inline nsites(h::HomogeneousSpin) = h.n_sites
@inline local_dim(h::HomogeneousSpin{D}) where D = D
@inline local_dim(h::HomogeneousSpin{D}, i) where D = D
@inline shape(h::HomogeneousSpin) = h.shape

@inline spacedimension(h::HomogeneousSpin) = local_dim(h)^nsites(h)
@inline indexable(h::HomogeneousSpin) = spacedimension(h) != 0
@inline is_homogeneous(h::HomogeneousSpin) = true

state(arrT::AbstractArray, T::Type{<:Number}, h::HomogeneousSpin{N}) where N =
    similar(arrT, T, nsites(h)) .= -(N-1)

Base.show(io::IO, ::MIME"text/plain", h::HomogeneousSpin{N}) where N =
    print(io, "Hilbert Space with $(nsites(h)) identical spins $(N-1)/2 of dimension $(local_dim(h))")

Base.show(io::IO, h::HomogeneousSpin) =
    print(io, "HomogeneousSpin($(nsites(h)), $(local_dim(h)))")


## Operations

function flipat!(rng::AbstractRNG, σ::AState, h::HomogeneousSpin{N}, i) where N
    T = eltype(σ)

    old_val = σ[i]
    new_val = T(rand(rng))
    new_val = floor(new_val*(N-1))*2 - (N-1)
    σ[i]    = new_val + 2 * (new_val >= old_val)
    return old_val, new_val
end

# special case N== 2 to be faster
function flipat!(rng::AbstractRNG, σ::AState, h::HomogeneousSpin{2}, i)
    T = eltype(σ)

    old_val = σ[i]
    new_val = old_val == 1.0 ? -1.0 : 1.0
    σ[i]    = new_val

    return old_val, new_val
end

function setat!(σ::AState, h::HomogeneousSpin, i::Int, val)
    old_val = σ[i]
    σ[i] = val

    return old_val
end

set_index!(σ::AState, h::HomogeneousSpin, i) = set!(σ, h, i)
function set!(σ::AState, h::HomogeneousSpin{N}, val::Integer) where N
    @assert val > 0 && val <= spacedimension(h)
    val -= 1

    for i=1:nsites(h)
        val, tmp = divrem(val, N)
        σ[i] = tmp * 2 - (N-1)
    end
    return σ
end

add!(σ::AState, h::HomogeneousSpin, val::Integer) =
    set!(σ, h, val+toint(σ, h))

function Random.rand!(rng::AbstractRNG, σ::Union{AState,AStateBatch}, h::HomogeneousSpin{N}) where N
    T = eltype(σ)
    rand!(rng, σ)
    σ .= floor.(σ.*N).*2 .- (N-1)
    return σ
end

function toint(σ::AState, h::HomogeneousSpin{N}) where N
    tot = 0
    for (i,v)=enumerate(σ)
        tot += Int((v + (N-1))/2)*N^(i-1)
    end
    return tot + 1
end

local_index(σ::AState, h::HomogeneousSpin{N}, site) where N = Int((σ[site] + (N-1))/2)+1

function local_index(σ::AState, h::HomogeneousSpin{M}, sites::AbstractVector) where M
    idx = 1
    for (i,j)=enumerate(sites)
        idx += Int((σ[j] + (M-1))/2) * M^(i-1)
    end
    return idx
end