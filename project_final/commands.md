# **Environment Setup*

Notes and logs  
https://gist.github.com/nov05/d8a9ce2e4bd991383381fcf683c6799e   


```julia
cd("D:/github/Stanford-AA228VProjects/project_final"); import Pkg; Pkg.activate(@__DIR__)
```

```julia
import Pkg; Pkg.upgrade_manifest()
```

```julia
Pkg.rm("AdversarialDriving"); rm("D:\\Users\\guido\\.julia\\dev\\AdversarialDriving"; force=true, recursive=true); rm("D:\\Users\\guido\\.julia\\packages\\AdversarialDriving"; force=true, recursive=true); Pkg.rm("POMDPSimulators"); rm("D:\\Users\\guido\\.julia\\dev\\POMDPSimulators"; force=true, recursive=true); rm("D:\\Users\\guido\\.julia\\packages\\POMDPSimulators"; force=true, recursive=true)
```



