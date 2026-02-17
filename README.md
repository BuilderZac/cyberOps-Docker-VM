This is a VM I have built up & maintained well taking CYB3801 in Spring 2026. 
It ships with all packages we have used in class + QOL like my nvim IDE config & OMZ config.
Only prerequsit on linux is to have docker installed.
On first launch it will create the live directery on your host system which maps to workspace inside the vm.

Run "compile" to build the docker file & "start" to launch the vm in the shell.
Start has the flag -h to use the host network if you want to access local services.
