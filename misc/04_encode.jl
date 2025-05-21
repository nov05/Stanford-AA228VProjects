using Base64

## encode k times and save as .project2
k = Int((typemax(UInt16) + 1)^(1 / 8))  ## 4
write("misc\\.project2", reduce((s, _) -> base64encode(s), 1:k; init=read("misc\\03_project2_decode_output.jl", String)))