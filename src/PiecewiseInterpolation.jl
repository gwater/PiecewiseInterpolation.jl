module PiecewiseInterpolation

using IntervalSets
using Dierckx
import Base: append!

export PiecewiseSpline1D, append!

immutable PiecewiseSpline1D{T <: Real}
    pieces::Vector{Spline1D}
    intervals::Vector{ClosedInterval{T}}
end

function (p::PiecewiseSpline1D)(t)
    i = findlast(interval -> t ∈ interval, p.intervals)
    return p.pieces[i](t)
end

function split_interval{T <: Real}(jumps::Vector{T},
                                   interval::ClosedInterval{T})
    isempty(jumps) && return [interval]
    intervals = Vector{typeof(interval)}(length(jumps) + 1)
    intervals[1] = interval.left..jumps[1]
    for i in 2:length(jumps)
        intervals[i] = jumps[i - 1]..jumps[i]
    end
    intervals[end] = jumps[end]..interval.right
    return intervals
end

function get_index_range{T}(times::Vector{T}, interval::ClosedInterval{T})
    f = t -> t ∈ interval
    return findfirst(f, times):findlast(f, times)
end

get_interpolation(times, values) =
    Spline1D(times, values, bc="extrapolate", k = min(5, length(times)))

function append!{T}(p::PiecewiseSpline1D{T}, new_times::Vector{T},
                    new_values::Vector, new_jumps::Vector{T})
    old_t_end = p.intervals[end].right
    if any(new_times .< old_t_end) || any(new_jumps .< old_t_end)
        error("new data overlaps with existing interpolations")
    end
    intervals = split_interval(new_jumps, old_t_end..new_times[end])
    for interval in intervals
        indices = get_index_range(new_times, interval)
        interpolation = get_interpolation(view(new_times, indices),
                                          view(new_values, indices))
        push!(p.pieces, interpolation)
        push!(p.intervals, interval)
    end
    return nothing
end

function PiecewiseSpline1D{T <: Real}(times::Vector{T}, values::Vector,
                                      jumps::Vector{T})
    assert(length(times) == length(values))
    # create object with first interval, then append remaining
    time_interval = times[1]..jumps[1]
    indices = 1:searchsortedlast(times, jumps[1])
    interpolation =
        get_interpolation(view(times, indices), view(values, indices))
    p = PiecewiseSpline1D([interpolation], [time_interval])
    rest_start = searchsortedfirst(times, jumps[1])
    append!(p, times[rest_start:end], values[rest_start:end], jumps[2:end])
    return p
end

end #module
