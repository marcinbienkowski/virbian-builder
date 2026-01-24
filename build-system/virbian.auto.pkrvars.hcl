# Target architecture: x86_64 or arm64
# Comment the line below and uncomment the next one to build for ARM (Apple Silicon)
arch = "x86_64"
# arch = "arm64"

# Below is the specification of machine for building the image only.
# The machine for running the image can be specified independently in register-virbian-in-virtualbox.sh
#   or manually in Virtualbox.
memory = 8192
cpus   = 4

# Use this for weaker machines:
# memory = 2048
# cpus   = 1

