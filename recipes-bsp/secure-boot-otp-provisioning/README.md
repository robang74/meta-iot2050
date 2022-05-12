# IOT2050 secure boot customer key provisioning

IOT2050 Advanced PG2 enables the SoC extend OTP area for storing the customer
key used for signing the firmware & software that validated by SEBoot and afterwards.

Below are the steps to programming keys into this OTP area.

## Create the keys

First, you need to generate at least two sets of key pair under the folder
`files/keys`. At most you can have three key pair sets. An example of key pairs
are already there for reference.

These keys are named `MPK`, `SMPK` and `BMPK` respectively.

```shell
openssl req -x509 -newkey rsa:4096 -keyout custMpk.pem -nodes -outform pem -out custMpk.crt -sha256
openssl req -x509 -newkey rsa:4096 -keyout custSmpk.pem -nodes -outform pem -out custSmpk.crt -sha256
# optional the third key
#openssl req -x509 -newkey rsa:4096 -keyout custBmpk.pem -nodes -outform pem -out custBmpk.crt -sha256
```

> :warning:
> Do remove the example dummy keys under the keys folder!

> :warning:
> Please securely take care of these keys!

## Building the signed firmware image containing the key provisioning data

The next step is to build the signed firmware image together with the key
provisioning data.

Before start the build, copy the currently using key set into folder
`recipes-bsp/u-boot/files/keys`.

```shell
./kas-container build kas-iot2050-boot-pg2.yml:kas/opt/secure-boot.yml:kas/opt/key-provision.yml
```

> Warning: The default key sets within kas/opt/key-provision.yml only contain
> MPK and SMPK. To include BMPK as well, please refer to [Flexible key provisioning](#flexible_key_provisioning).

## Update the firmware to provisioning the keys

Copy the built firmware image to IOT2050 and run the firmware update against the
new firmware image:

```shell
iot2050-firmware-update -f iot2050-pg2-image-boot.bin
```

Reboot the IOT2050 and follow the instruction on the device. The debug serial 
port has to be connected to give your consent to the provisioning routine.

> Warning: after provisioning, all application must be signed with the currently
> using key.

The key provisioning just need be run once. Later secure boot firmware building
should drop the `kas/opt/key-provision.yml`

## Revoke the leaked currently using key

If unfortunately the currently using key is leaked, you could switch to use the
next keysets as the effective one.

First make sure both the old key and the new key reside in `recipes-bsp/u-boot/files/keys`.

Then start to building the new key signed firmware together with the key switching
otpcmd data.

```shell
./kas-container build kas-iot2050-boot-pg2.yml:kas/opt/secure-boot.yml:kas/opt/key-switch.yml
```

> Warning: The default switching within kas/opt/key-switch.yml is from MPK to SMPK.
> If you want to switch from SMPK to BMPK, please refer to [Flexible key provisioning](#flexible_key_provisioning).

Then follow the exact same steps as defined in above, to update the firmware and
follow the instructions on device after rebooting.

## Flexible key provisioning

The otpcmd data produced by the default `kas/opt/key-provision.yml` contains

- the MPK and SMPK key sets
- control bit that enabling the secure boot

Sometimes it would be helpful to have different configurations. This could be done
by passing different parameters to:
`recipes-bsp/secure-boot-otp-provisioning/files/make-otpcmd.sh`
and have different configurations in
`recipes-bsp/secure-boot-otp-provisioning/files/its/key-provision.its`

### Provision the additional BMPK

If the BMPK need to be programmed together, before building the firmware, link
the `files/its/key-provision.its` to `key-provision-3keys.its.template`, then
uncomment below line in `meta-iot2050/kas/opt/key-provision.yml`:

```
# OTP_BMPK ?= "./keys/custBmpk.pem"
```

### Provision keys only without enabling secure boot

If only the keys need to be programmed but not enabling the secure boot, link the
`files/its/key-provision.its` to `key-provision-only-keys.its.template` before 
building the firmware.

### Enable secure boot only

If only enabling the secure boot need to be programmed, link the
`files/its/key-provision.its` to `key-provision-only-enable.its.template` before 
building the firmware.

### Switch from SMPK to BMPK

If the key switching is from SMPK to BMPK, uncomment below lines in
`meta-iot2050/kas/opt/key-switch.yml`:

```
# OTP_MPK = ""
# OTP_SMPK = "./keys/custSmpk.pem"
# OTP_BMPK = "./keys/custSmpk.pem"
```
