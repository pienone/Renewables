#RENEWABLES ASSIGNMENT 1

#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV
using LinearAlgebra
using RCall
using Plots
using DataFrames
#@rlibrary ggplot2



T= collect(1:1464)      #End of nov: 720
Tnov=collect(1:720)     #NOV
Tjan=collect(721:1464)  #JAN
R= collect(1:2)         #Regions
G= collect(1:15)        #Generators
G_DK1= collect(1:7)     #Generators DK1
G_DK2= collect(8:15)    #Generators DK2
WIND= collect(1:4)      #Wind Generators DK1
WWIND= collect(1:2)     #Wind Generators DK1
EWIND= collect(3:4)     #Wind Generators DK2
IMP=collect(1:2)        #Importers



#data acquisition
path="C:/Users/pietr/Documents/DTU/Renewables in electricity markets"
X = CSV.read("$path/assignment1.csv", delim=",")


#GENERATION
Qg=[X.G1,X.G2,X.G3,X.G4,X.G5,X.G6,X.G7,X.G8,X.G9,X.G10,X.G11,X.G12,X.G13,X.G14,X.G15]
QgW=[X.WW1,X.WW2,X.EW1,X.EW2]
Imp1=X.NOimp
Imp2=X.SWimp

#PRICES
pg=[72,62,150,80,87,24,260,17,44,40,37,32,5,12,235]
Supp=[0,17,20,12]
pw=-1*Supp

#DEMAND
D_DK1=X.ConsDK1+X.DEexp
D_DK2=X.ConsDK2
D_tot=D_DK1+D_DK2


#TRANSMISSION
TC=600          #transmission capacity between DK1 and DK2


#LOAD SHEDDING
LSCost=100000000000000     #load shedding cost 


#######   ANALYSIS
VOLUMES=zeros(length(T),length(G)+length(WIND))
VOLUMESWIND=zeros(length(T),length(WIND))
REVENUES=zeros(length(T),length(G)+length(WIND))
REVENUESWIND=zeros(length(T),length(WIND))
TOTREVENUES=zeros(length(G)+length(WIND))
PRICES=zeros(length(T),2)
FLOW=zeros(length(T))
LOADSHEDDING=zeros(length(T))





#######   LINEAR PROGRAM


for t in T
        model_market = Model(with_optimizer(Gurobi.Optimizer))

        @variable(model_market, 0<=qg[g in G])
        @variable(model_market, 0<=qw[w in WIND])
        @variable(model_market, -TC<=F<=TC)
        @variable(model_market, 0<=LS)

        @objective(model_market, Min, sum(pg[g]*qg[g] for g in G)+sum(pw[w]*qw[w] for w in WIND))

        @constraint(model_market, equality1, sum(qg[g] for g in G_DK1)+sum(qw[w] for w in WWIND)+Imp1[t] - (D_DK1[t])==F)
        @constraint(model_market, equality2, sum(qg[g] for g in G_DK2)+sum(qw[w] for w in EWIND)+Imp2[t] - (D_DK2[t])==-F)

        @constraint(model_market, maxproductionG[g in G], qg[g]<=Qg[g][t])
        @constraint(model_market, maxproductionW[w in WIND], qw[w]<=QgW[w][t])

        optimize!(model_market)

#OUTPUT

for g in G
        VOLUMES[t,g]=value.(qg[g])
end

for w in WIND
        VOLUMES[t,w+length(G)]=value.(qw[w])
end

for g in G_DK1
        REVENUES[t,g]=(value.(qg[g]))*(dual.(equality1))
end

for g in G_DK2
        REVENUES[t,g]=(value.(qg[g]))*(dual.(equality2))
end

for w in WWIND
        REVENUES[t,w+length(G)]=(value.(qw[w]))*(dual.(equality1))
end

for w in EWIND
        REVENUES[t,w+length(G)]=(value.(qw[w]))*(dual.(equality2))
end

for g in collect(1:(length(G)+length(WIND)))
        TOTREVENUES[g]=sum(REVENUES[g,:])
end



FLOW[t]=value.(F)
PRICES[t,1]=dual.(equality1)
PRICES[t,2]=dual.(equality2)
LOADSHEDDING[t]=value.(LS)
RESULTS=hcat(VOLUMES,REVENUES,PRICES,FLOW,LOADSHEDDING)

end


df_P=DataFrame(PRICES)
CSV.write("$path/Results_prices.csv", df_P)

df_V=DataFrame(VOLUMES)
CSV.write("$path/Results_volumes.csv", df_V)

df_R=DataFrame(REVENUES)
CSV.write("$path/Results_revenues.csv", df_R)

df_FLS=DataFrame(hcat(FLOW,LOADSHEDDING))
CSV.write("$path/Results_flow.csv", df_FLS)

df_TR=DataFrame(hcat(TOTREVENUES))
CSV.write("$path/Results_totrevenues.csv", df_TR)




plot(PRICES[:,1])
plot!(PRICES[:,2])
savefig("$path/Prices.png")

