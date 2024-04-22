source("renv/activate.R")

options(clustermq.scheduler = "ssh",
        clustermq.ssh.host = "hpcuser@login.hpc.org",  # use your user and host, obviously
        clustermq.ssh.log = "cmq_ssh.log", # log for easier debugging (file exists on the remote server!)
        clustermq.ssh.hpc_fwd_port = 10000:11000,
        clustermq.template = "ssh.tmpl"
        )

options(repos=c(CRAN="https://packagemanager.posit.co/cran/latest"))
