# Using {clustermq} for remote submission to a HPC cluster

## Introduction

{clustermq} is an R package that allows you to send function calls to a HPC cluster with a minimal interface provided by the `Q()` function. It supports all major HPC [schedulers](https://mschubert.github.io/clustermq/index.html#schedulers). It also has a so-called SSH connector that allows running computations remotely through an ssh tunnel via port forwarding. 

The compute backend specific details are largely abstracted out and hidden in so-called templates. As a consequence it is very easy to run the same code with little or no changes on different compute backends. 

{clustermq} does not create any transient files and hence does not cause a strain on storage. {clustermq} uses the zeromq framework for communications.

There is times when a user is developing a compute intensive code and soon is outstripping the capabilities of the local workstation. While this would be the time to move over to a more scalable infrastructure such as an HPC cluster. Instead of doing a lift and ship, {clustermq} can be used to nest the SSH connector with the HPC backend so that a user can run the code directly from his/her workstation. Any communication will happen via `ssh` and on the cluster the `zeromq` protocol is being used. 

## General overview 

![][def]

In the above diagram the solution is presented: On the left there is the User Workstation where the user is developing code (say in the RStudio IDE). {clustermq} is building an ssh tunnel to the HPC login node and triggering the `clustermq::ssh_proxy` process there. This proxy will also submit worker jobs to the HPC cluster and create a local master process that is waiting for the workers to ask for work upon which this process will push the work to the workers.

**Note**: The home-directory and R installation on the workstation is different from the one of the HPC cluster.

## Prerequisites

HPC cluster must allow remote ssh access to a login node. The login node also should allow connections to a port or port range other than the ssh port in order to establish the ssh tunnel.

For the example in this repo, we assume 
* ssh key is `~/.ssh/hpc.key`
* HPC login node DNS name is `login.hpc.org`
* HPC user name is `hpcuser`
* HPC login node allows connections on ports 10000...11000
* 

### Setting up passwordless ssh (One time setup)

First we need to set up passwordless ssh to the HPC cluster. 

Let's set up a new ssh key for this purpose:

```
ssh-keygen -f ~/.ssh/hpc.key
```
and press "Enter" twice.

Now let's copy the new key over to the HPC. The next command will ask you for your HPC user password. 

```
ssh-copy-id -i ~/.ssh/hpc.key hpcuser@login.hpc.org
```

As a test you now should be able to log into the remote HPC cluster without password using `ssh -i ~/.ssh/hpc.key hpcuser@login-node.hpc.org`.

**Note**: We are using a specifc ssh key for the HPC connection. As a consequence we need to modify the default ssh connector template and point to this ssh key (cf. [ssh.tmpl](ssh.tmpl))

### R and R package management

Given the fact that the home directories of the workstation and the HPC cluster are different, there are different R installations on both environments, care has to be taken to reflect those differences.

#### Difference in R installations 

Changes have to be reflected in the used templates ([ssh.tmpl](ssh.tmpl) and slurm.tmpl in our case). For our test setup fortunately there is no need for any changes.

### R package management. 

Since the home-directories of the workstation and the HPC cluster are different, the R packages used in the workstation do not necessarily exist on the HPC cluster. 

As a mitigation we are taking an inventory of all the installed packages available in the R session on the workstation, send this list over to the HPC login node and install the same R packages in the same versions in a custom folder (e.g. `~/.clustermq/libs`). This folder ideally should be separate for each project. The function `init()` has been implemented for this purpose. It uses [{pak}](https://pak.r-lib.org/) behind the scenes to ensure efficient and fast package installation.

In the `compute()` function we then set `.libPaths()` to the same folder where the libraries are available and then load the packages needed. {clustermq} would also support exporting the packages to the worker nodes but this is not possible here due to the different `.libPaths()` we are relying on. 

### Setting up `.Rprofile`

We are using a [`.Rprofile`](.Rprofile) locally in the projec folder that has the ssh connector definition. On the HPC cluster we need to deploy [`.Rprofile-hpc`](.Rprofile-hpc) as `.Rprofile` in the user's home-directory. 

## Running the code 

Once everything is set up, `test.R` should run successfully

## Troubleshooting 

### ssh connection errors 

Take a look into `cmq_ssh.log` on the login node to see if there is an error. 

### SLURM errors 

General submission errors are displayed to stderr in the running R session on the workstation. If the ssh connection succeeds but the execution is stuck, please consult the error logs in the user's home directory on the login node. There should be files named `cmq-XXXX-Y.log` where `XXXX` is the port number and `Y` the task ID of the respective SLURM job. 

[def]: img/remote-clustermq.png