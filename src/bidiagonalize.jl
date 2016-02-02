"""
Packed storage of bidiagonalizing QR reflectors.
"""
immutable PackedUVt{T}
    A::Matrix{T}
end


"""
Bidiagonalize a tall matrix `A` into `B`. Both arguments are overwritten.
"""
function bidiagonalize_tall!{T}(A::Matrix{T},B::Bidiagonal)
    m, n = size(A)
    # tall case: assumes m >= n
    # upper bidiagonal

    for i = 1:n
        x = slice(A, i:m, i)
        τi = LinAlg.reflector!(x)
        B.dv[i] = real(A[i,i])
        LinAlg.reflectorApply!(x, τi, slice(A, i:m, i+1:n))
        A[i,i] = τi # store reflector in diagonal coefficient

        # for Real, this only needs to be n-2
        # needed for Complex to ensure superdiagonal is Real
        if i <= n-1
            x = slice(A, i, i+1:n)
            conj!(x)
            τi = LinAlg.reflector!(x)
            B.ev[i] = real(A[i,i+1])
            LinAlg.reflectorApply!(slice(A, i+1:m, i+1:n), x, τi)
            A[i,i+1] = τi
        end
    end
    B.isupper = true

    B, PackedUVt(A)
end

function bidiagonalize_tall!{T}(A::Matrix{T})
    m,n = size(A)
    R = real(T)
    B = Bidiagonal(Array(R,n),Array(R,n-1),true)
    bidiagonalize_tall!(A,B)
end

function Base.full{T}(P::PackedUVt{T};thin=true)
    A = P.A
    m,n = size(A)

    # U = Q_1 ... Q_n I_{m,n}
    w = thin ? n : m
    U = eye(T,m,w)
    for i = n:-1:1
        τi = A[i,i]
        x = slice(A, i:m, i)
        LinAlg.reflectorApply!(x, τi', slice(U, i:m, i:w))
    end

    # Vt = P_{n_2} ... P_1
    Vt = eye(T,n,n)
    for i = n-1:-1:1
        τi = A[i,i+1]
        x = slice(A, i, i+1:n)
        LinAlg.reflectorApply!(slice(Vt, i:n, i+1:n), x, τi')
    end
    U,Vt
end