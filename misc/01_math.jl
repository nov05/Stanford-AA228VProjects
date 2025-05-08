## created by nov05 on 2025-05-07
## Or check the Colab notebook - https://colab.research.google.com/drive/1kgsRaZeUY9lT_zHba0taDr1K_MDTTbYi
#=
    This file includes example code from the following video.
    https://www.youtube.com/watch?v=KlorfxsdWDw
=#
## Alt+JO to open the Julia REPL terminal
## Ctrl+Enter to evalute a line

1 + 1
5 / 2
2^3
## 5 modulo 2
5 % 2
1 + (2-3)^4 * 5

## Boolean
3 > 2
3 < 2
4 >= 3
4 == 3
(1==1) && (1>1)
(1==1) || (1>1)

## variables
i = 1
i += 1
height = 2; width = 3; area = height * width
x = 8
x >>= 1

## https://docs.julialang.org/en/v1/base/numbers/
typeof(-3)
typeof(3.0)
example::Float32 = 1.2
typeof(example)
typeof(1//3)
1//3 + 1//7
pi
typeof(pi)
round(pi, digits=5)
1000000 == 1_000_000

## \div<tab>
4 ÷ 2
typeof(5 ÷ 2)

## character and string
typeof('c')
typeof("c")
println("Say \"Hello, Julia!\"")
println("""Say "Hello, Julia!" and come over.""")
s1 = "Hello,"; s2 = " world!"; print(s1 * s2)
print("$s1$s2")
## \alpha<tab>
Α = 0; α = 0
typeof(α)
typeof('α')
## \:dog:<tab>
typeof('🐶')
## \pi<tab>
π
## \euler<tab>
ℯ


## array
## col-vector
col_vector = [1, 2, 3]
typeof(col_vector)
length(col_vector)
sum(col_vector)
## row-vector
row_vector = Float32[4 5 6]
typeof(row_vector)
length(row_vector)
## 1-based indexing
col_vector[1]
row_vector[2]

## sum elements
sum(col_vector)
sum(row_vector)
sort([3,4,2,4,6,7,87], rev=true)
## sort destructively, "in-place"
v = [4,6,7,8,3,2,5,0]
sort!(v, rev=true)
v
push!(v, 100)
v
pop!(v)
v

matrix = [1 2 3; 4 5 6]
typeof(matrix)
matrix[1, 3]
## column-major order
matrix[5]
multi_types_matrix = [
    1 2.0 3//2;
    '🐕' 'd' "dog"
]
typeof(multi_types_matrix)

## dictionary
dog_dict = Dict(
    "name" => :eggdog,
    :age => 3,
    23 => "egg-dog mix"
)
dog_dict["name"]