module PiecewiseInterpolation

using Dierckx

export update_interpolations!, interpolation, rate_velocity

#TODO check if we still use this function
function rate_velocity(v1, v2)
    diff_v = vecnorm(v2, 2) - vecnorm(v1, 2)
    return max(diff_v, zero(diff_v))
end

function append_interpolation!(interpolations, times, values, tau)
    n_last_tau = length(interpolations) - 1
    # searchsorted returns a range; its `stop` is the last index before `t`
    begin_i  = searchsorted(times, n_last_tau * tau).stop
    end_i = searchsorted(times, (n_last_tau + 1) * tau).stop
    index_diff = end_i - begin_i
    if index_diff < 1
        error("insufficient data")
    end
    order = min(5, index_diff)
    interpolation = Spline1D(view(times, begin_i:end_i),
                             view(values, begin_i:end_i), k = order)
    push!(interpolations, interpolation)
end

function update_interpolations!(interpolations, times, values, tau)
    n_tau = ceil(Int, times[end] / tau)
    if length(interpolations) == n_tau
        # remove the last interpolation, so we can update it
        pop!(interpolations)
    end
    while length(interpolations) < n_tau
        try
            append_interpolation!(interpolations, times, values, tau)
        catch
            break
        end
    end
    return nothing
end

function interpolation{T <: Real}(t::T, interpolations, tau::T,
                                  history::Function)
    if t <= 0
        return history(t)
    end
    piece_n = ceil(Int, t / tau)
    return interpolations[piece_n](t)
end

end #module
