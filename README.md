# PiecewiseInterpolation

A simple interface for interpolations on timeseries with first order discontinuities (using [Dierckx.jl](https://github.com/kbarbary/Dierckx.jl)).

The module exports one new type, `PiecewiseSpline1D`, and extends one function, `append!()`.

    PiecewiseSpline1D(times::Vector, values::Vector, jumps::Vector)

Construct a spline interpolation which takes into account discontinuties listed in `jumps`.
Any `PiecewiseSpline1D` object `p` can be called as a function, i.e. `p(t)`.

    append!(p::PiecewiseSpline1D, new_times, new_values, new_jumps)

Extend an existing spline `p` with new data.

**A practical example can be found in our [demo notebook](demo.ipynb).**
