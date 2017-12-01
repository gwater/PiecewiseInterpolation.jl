module PiecewiseInterpolation

using Dierckx

import Base: append!

export PieceInterpolation, append!

immutable PieceInterpolation{T <: Real}
    pieces::Vector{Spline1D}
    intervals::Vector{Tuple{T, T}}
end

function (p::PieceInterpolation)(t)
    i = searchsortedlast(p.intervals, t, by=interval -> interval[1])
    return p.pieces[i](t)
end

function get_time_intervals{T <: Real}(jumps::Vector{T},
                                       t_start::T, t_end::T)
    if length(jumps) == 0
        return [(t_start, t_end)]
    end
    a = Vector{Tuple{T, T}}(length(jumps) + 1)
    a[1] = (t_start, jumps[1])
    for i in 2:length(jumps)
        a[i] = (jumps[i - 1], jumps[i])
    end
    a[end] = (jumps[end], t_end)
    return a
end

get_index_interval(times, t_start, t_end) =
    searchsortedfirst(times, t_start):searchsortedlast(times, t_end)

get_interpolation(times, values) =
    Spline1D(times, values, bc="extrapolate", k=min(5, length(times)))

function append!{T}(p::PieceInterpolation{T}, new_times::Vector{T},
                    new_values::Vector, new_jumps::Vector{T})
    assert(length(new_times) == length(new_values))
    old_t_end = p.intervals[end][2]
    if any(new_times .< old_t_end) || any(new_jumps .< old_t_end)
        error("new data overlaps with existing interpolations")
    end
    time_intervals = get_time_intervals(new_jumps, old_t_end, new_times[end])
    for time_interval in time_intervals
        indices = get_index_interval(new_times, time_interval...)
        interpolation = get_interpolation(view(new_times, indices),
                                          view(new_values, indices))
        push!(p.pieces, interpolation)
        push!(p.intervals, time_interval)
    end
    return nothing
end

function PieceInterpolation{T <: Real}(times::Vector{T}, values::Vector,
                                       jumps::Vector{T})
    assert(length(times) == length(values))
    # create object with first interval, then append remaining
    time_interval = (times[1], jumps[1])
    indices = 1:searchsortedlast(times, jumps[1])
    interpolation =
        get_interpolation(view(times, indices), view(values, indices))
    p = PieceInterpolation([interpolation], [time_interval])
    rest_start = searchsortedfirst(times, jumps[1])
    append!(p, times[rest_start:end], values[rest_start:end],
            jumps[2:end])
    return p
end

end #module
