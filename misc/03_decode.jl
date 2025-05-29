using Base64

## Check ".julia\packages\StanfordAA228V\h5BcH\src\notebook\backend.jl"
# process(fn, t=tempname(), k=Int((typemax(UInt16) + 1)^(1 / 8))) = [[
#     begin
#         fn = let c = base64decode(read(fn, String))
#             open(t, "w+") do f
#                 write(f, c)
#             end
#             t
#         end
#     end for _ ∈ 1:k
# ], t][end]

## decode k times and save the output to a local file
encoded = read(joinpath(@__DIR__, "..\\.julia\\packages\\StanfordAA228V\\h5BcH\\src\\notebook\\.project3"), String)
k = Int((typemax(UInt16) + 1)^(1 / 8))  ## 4
# decoded = reduce((s, _) -> String(base64decode(s)), 1:k; init=encoded)
# println(decoded)
write("misc\\03_project3_decode_output.jl", reduce((s, _) -> String(base64decode(s)), 1:k; init=encoded))