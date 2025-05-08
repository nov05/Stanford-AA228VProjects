## created by nov05 on 2025-05-07
#=
    This file includes example code from the following video.
    https://www.youtube.com/watch?v=KlorfxsdWDw
    Or check the Colab notebook  
    https://colab.research.google.com/drive/1kgsRaZeUY9lT_zHba0taDr1K_MDTTbYi
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

## dictionary and symbol
dog_dict = Dict(
    "name" => :eggdog,
    :age => 3,
    23 => "egg-dog mix"
)
dog_dict["name"]
dog_dict[:email] = "dog@gmail.com"
dog_dict
pop!(dog_dict, :email)
dog_dict

mutable struct Dog 
    name::String
    age::Integer
    email::String
end
my_dog = Dog("π", 6, "pi@gmail.com")
typeof(my_dog)
my_dog.name

## condition
x, y = 1, 2
x, y = y, x
x = y
println(x, "\t", y)
x, y = 1, 2
task_1() = println("$x > $y")
task_2() = println("$x < $y")
task_3() = println("$x == $y")
if x > y 
    task_1()
elseif x < y
    task_2()
else
    task_3()
end

## ternary operator
x > y ? task_1() : println("$x <= $y")
x > y ? task_1() : (x < y ? task_2() : task_3())

## while-loop
i = 1
while i < 10
    println(i)
    i += 1
end

## for-loop
for i = 1:10
    println(i)
end
for i = 0:3:12
    println(i)
end

## list comprehension 
[i^2 for i in 1:3]

## function overloading
function mytypeof(x::Int64)
    return("integer")
end
function mytypeof(x::Number)
    return("number")
end
function mytypeof(x::Any)
    return("any")
end
## mutiple dispatch
function mygenericfunction(x)
    println(
        "The type of x is: ",
        mytypeof(x)
    )
end
mygenericfunction(3)
mygenericfunction(2.0)
mygenericfunction('🐶')
methods(mygenericfunction)
methods(mytypeof)
methods(+)

## anounymous function
map(x -> x*" world!", ["Hello"])

## standard function
using Random
Random.seed!(1)
rand(10)
using Statistics
mean(randn(10000))
median(randn(10000))
std(randn(10000))

## external packages
#=
    $ pwd()
    $ cd("misc")
    $ ]
    (@v1.11) pkg> activate .
    (misc) pkg> add Plots
    ## backspace to exit
=#
using Plots
f(x) = x^3 - 2x
plot(f)
using Random
Random.seed!(42)
scatter(randn(1000), randn(1000))
closeall()
GC.gc()

## Pluto
## https://nov05.github.io/htmls/stanford/Stanford-AA228VProjects/02_Pluto.html
import Pluto
Pluto.run()

## Julia version
versioninfo()
#=
julia> versioninfo()
Julia Version 1.11.5
Commit 760b2e5b73 (2025-04-14 06:53 UTC)
Build Info:
  Official https://julialang.org/ release
Platform Info:
  OS: Windows (x86_64-w64-mingw32)
  CPU: 12 × Intel(R) Core(TM) i7-10750H CPU @ 2.60GHz
  WORD_SIZE: 64
  LLVM: libLLVM-16.0.6 (ORCJIT, skylake)
Threads: 1 default, 0 interactive, 1 GC (on 12 virtual cores)
Environment:
  JULIA_DEPOT_PATH = D:\Users\guido\.julia
  JULIA_EDITOR = code
  JULIA_NUM_THREADS =
=#

## help
## type ? for help, ]? for package help