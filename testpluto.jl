### A Pluto.jl notebook ###
# v0.18.4

using Markdown
using InteractiveUtils

# ╔═╡ c6c91330-7aff-46a9-a985-7cf36ae6f8d6
import Pkg; Pkg.add(url="https://github.com/rbontekoe/AppliAR")

# ╔═╡ 74bf5433-9625-4115-8732-e08e439a0c04
using Sockets, Serialization, AppliSales, AppliAR, AppliGeneralLedger, DataFrames, Query

# ╔═╡ eb06a801-89ad-4ba0-90af-b34695fb4f72
md"""
### TCP Socket application with MicroK8s on Ubuntu 20.04

"MicroK8s is a powerful, lightweight, reliable production-ready Kubernetes distribution. It is an enterprise-grade Kubernetes distribution that has a small disk and memory footprint while offering carefully selected add-ons out-the-box, such as Istio, Knative, Grafana, Cilium and more. Whether you are running a production environment or interested in exploring K8s, MicroK8s serves your needs," see [Introduction to MicroK8s](https://ubuntu.com/blog/introduction-to-microk8s-part-1-2).
"""

# ╔═╡ a8dbdd3a-0e93-460b-ac95-67402d065560
md"""
#### The model

AccountReceivable and GeneralLedger are microservices. We use sockets for communication.

To create statefulset pods we used Suyash Mohan article [Setting up PostgreSQL Database on Kubernetes](https://medium.com/@suyashmohan/setting-up-postgresql-database-on-kubernetes-24a2a192e962) as a guideline.
```
                         Store
                           ↕
                       Counter (cnt)
                           ↓
    testpluto.jl          Invoice Nbr
          ↓                ↓
      Orders/ → AccountsReceivable (ar) → Entries → GeneralLedger (gl)
  BankStatements           ↕                               ↕
                         Store                           Store
                  Unpaid/PaidInvoices            Journal/GeneralLedger
```
"""

# ╔═╡ f9eb09c0-37e1-41d9-af47-91d86ac43742
md"""
#### Check whether ar-statefulset, gl-statefullset and cnt-statefullset pods are running

Run the next command from the terminal:

**microk8s.kubectl get pods -n socket-ns**

```
NAME                READY   STATUS    RESTARTS   AGE
cnt-statefulset-0   2/2     Running   0          160m
gl-statefulset-0    2/2     Running   0          159m
gl-statefulset-1    2/2     Running   0          159m
ar-statefulset-1    2/2     Running   0          98m
ar-statefulset-0    2/2     Running   0          97m
```
"""

# ╔═╡ 8da871f0-d6b8-494d-ab99-bb68d7045d7c
md"""
#### If pods are not running use next commands from the terminal
- Install microk8s: **sudo snap install microk8s --classic**
- Enable microk8s build-in apps: **microk8s enable registry dashboard dns istio storage**
- Clone files from GitHub: **git clone https://github.com/rbontekoe/ar.git**
- Enter the folder with the downloaded files: **cd ar**
- Download Julia 1.6.5: **curl -O https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.5-linux-x86_64.tar.gz**
- Create accounts receivable image: **docker build --no-cache -f ar.Dockerfile -t localhost:32000/i_ar:v1.0.16 .**
- Copy to local registry: **docker push localhost:32000/i_ar:v1.0.16**
- Create general ledger image: **docker build --no-cache -f gl.Dockerfile -t localhost:32000/i_gl:v1.0.3 .**
- Copy to local registry: **docker push localhost:32000/i_gl:v1.0.3**
- Create counter image: **docker build --no-cache -f cnt.Dockerfile -t localhost:32000/i_cnt:v1.0.1 .**
- Copy to local registry: **docker push localhost:32000/i_cnt:v1.0.1**
- **microk8s.kubectl apply -f ar-storage.yaml**
- **microk8s.kubectl apply -f cnt-storage.yaml**
- **microk8s.kubectl apply -f gl-storage.yaml**
"""

# ╔═╡ e872e5c6-2221-474e-bf2b-ecca6dbf6004
md"""
#### Import AppliAR.jl
"""

# ╔═╡ 19b11012-d491-457e-b8a3-702f308dd374
md"""
#### Load the files
"""

# ╔═╡ 5f81a10d-052f-44c9-ad48-a9c290450035
md"""
#### Delete the old data files

Go to the terminal and delete the next files:

sudo rm /var/data-ar/*
"""

# ╔═╡ 475e6f3f-e218-4d2d-bfb4-3e80ed334d38
md"""
#### Connect to AppliAR.jl, create and process the orders
"""

# ╔═╡ 8d0f3ea7-6d4e-4305-bcd4-a4a621fadbd6
clientside = connect(ip"127.0.0.1", 30012) # connect to accounts receivable pod

# ╔═╡ 77310d18-97a1-4aa6-8cd8-626ce6784444
sales = AppliSales.process() # create sales orders

# ╔═╡ 66de6da9-1349-4a17-8e90-f87b8b675ca9
block_run = false

# ╔═╡ f711fad3-260c-4154-ba51-ed1a12d2f45a
if block_run
	serialize(clientside, sales) # send orders to account receivable
end

# ╔═╡ e7f6bcea-8fa8-4fe7-8151-f0be1d2be017
begin
	r0 = AppliGeneralLedger.read_from_file("/var/data-ar/generalledger.txt")
	df1 = r0 |> @filter(_.accountid == 1300) |> DataFrame
	df1[:, [:accountid, :customerid, :invoice_nbr, :debit, :credit, :descr]]
end

# ╔═╡ b515d44e-bc74-4293-aa1c-9cce8cfafc06
md"""
#### Load and process the bank statements
"""

# ╔═╡ 10e1d308-1220-4326-be70-4c67264061f1
if block_run
    stms = AppliAR.read_bank_statements("./bank-kubernetes.csv") # retrieve the bankstatements
end

# ╔═╡ 1e52dabe-2477-4c17-9ac5-43b92047bc2a
if block_run
	serialize(clientside, stms) # create paid invoices and update general ledger
end

# ╔═╡ 8748e4ca-d3ac-47e3-b97d-6b083c95e9f6
md"""
#### Display Accounts Receivable

Other accounts are:

```
8000 - Sales
1150 - Bank
4000 - VAT
1300 - Accounts Receivable
```
"""

# ╔═╡ 8cf84474-6db5-451e-bf32-546e042850c4
accountid = 1300;

# ╔═╡ 5c6f554e-adc0-4a66-80c8-392e052af8cc
begin
	r2 = AppliGeneralLedger.read_from_file("/var/data-ar/generalledger.txt")
	df2 = r2 |> @filter(_.accountid == accountid) |> DataFrame
	df2[:, [:accountid, :customerid, :invoice_nbr, :debit, :credit, :descr]]
end

# ╔═╡ ad8e9725-bccc-4651-909e-312a5af298ac
md"""
#### Display the status of the unpaid invoices
"""

# ╔═╡ 74629051-dd8c-4e0e-b914-4f523ccbf8d7
begin
	r1 = AppliAR.aging("/var/data-ar/unpaid-invoices.txt", "/var/data-ar/paid-invoices.txt")
	result = DataFrame(r1)
end

# ╔═╡ Cell order:
# ╟─eb06a801-89ad-4ba0-90af-b34695fb4f72
# ╟─a8dbdd3a-0e93-460b-ac95-67402d065560
# ╟─f9eb09c0-37e1-41d9-af47-91d86ac43742
# ╟─8da871f0-d6b8-494d-ab99-bb68d7045d7c
# ╟─e872e5c6-2221-474e-bf2b-ecca6dbf6004
# ╠═c6c91330-7aff-46a9-a985-7cf36ae6f8d6
# ╟─19b11012-d491-457e-b8a3-702f308dd374
# ╠═74bf5433-9625-4115-8732-e08e439a0c04
# ╟─5f81a10d-052f-44c9-ad48-a9c290450035
# ╟─475e6f3f-e218-4d2d-bfb4-3e80ed334d38
# ╠═8d0f3ea7-6d4e-4305-bcd4-a4a621fadbd6
# ╠═77310d18-97a1-4aa6-8cd8-626ce6784444
# ╠═66de6da9-1349-4a17-8e90-f87b8b675ca9
# ╠═f711fad3-260c-4154-ba51-ed1a12d2f45a
# ╠═e7f6bcea-8fa8-4fe7-8151-f0be1d2be017
# ╟─b515d44e-bc74-4293-aa1c-9cce8cfafc06
# ╠═10e1d308-1220-4326-be70-4c67264061f1
# ╟─1e52dabe-2477-4c17-9ac5-43b92047bc2a
# ╟─8748e4ca-d3ac-47e3-b97d-6b083c95e9f6
# ╠═8cf84474-6db5-451e-bf32-546e042850c4
# ╠═5c6f554e-adc0-4a66-80c8-392e052af8cc
# ╟─ad8e9725-bccc-4651-909e-312a5af298ac
# ╠═74629051-dd8c-4e0e-b914-4f523ccbf8d7
