# Ephemeros

Tools and configuration for provisioning OS diskless Container Linux clusters,
running [k3s](https://k3s.io) and logging with
[Papertrail](https://papertrail.com). Nodes boot from an iPXE flash drive,
which also contains a dedicated volume for keeping secrets.

The iPXE script downloads and boots the newest stable release for Flatcar
Container Linux (RIP CoreOS), which then pulls in the
[ignition.ign](ignition.ign) file in this repo.

Since that is publicly visible, we cannot have any secrets kicking around in
there. But we still need those values to be carried over somehow, so we capture
those values at iPXE flash drive provisioning-time and throw them into the
`secrets` volume. From there, all service definitions pull what they need from
`/secrets`, which is readonly mounted.

## Making boot media

Pop in a flash drive you don't care about and then run the following:

```shell
sudo \
    SSH_KEY_PATH=$HOME/.ssh/id_rsa.pub \
    NODE_HOSTNAME=node1337 \
    PAPERTRAIL_HOST=logsX.papertrailapp.com PAPERTRAIL_PORT=XXXXX \
    UPTIMEROBOT_HEARTBEAT_PATH=biglongopaquethingitgivesyou \
    K3S_TOKEN="you should really set this to something secret" \
    # Other K3S_* env vars you probably want to set \
    ./build_pxe_stick.sh /dev/sdX
```

If you don't specify expected `PAPERTRAIL_*`, `UPTIMEROBOT_*` or `K3S_*`, we'll
throw up a warning in `build_pxe_stick.sh` and those components won't be
activated at system runtime.

## Updating the Ignition configs

The [ignition.ign](ignition.ign) file is generated from the
[ignition.yml](ignition.yml) file. You can perform that tranformation with
the following:

```shell
bash ./ignite.sh ignition.yml > ignition.ign
```

Note that the ignition config is pulled down from github each boot, so you'll
need to push any changes in order to test them. There's likely some room here
for certain iPXE values (such as the ignition config URI) to be derived from
the git repo itself...

## Testing with qemu

You can have qemu boot the flash drive for testing purposes. Note that this
will result in downloading several hundred megabytes each run. To do this use:
`./qemu_test /dev/sdX`. If you get stuck in the console, then `alt-2` and then
`quit` should get you out. You can also run it with `NO_CURSES=1` environment
variable set if you want your console in a dedicated graphical window rather
than a terminal:

```shell
NO_CURSES=1 ./qemu_test /dev/sdX
```

Then you can just `ssh core@localhost -p 2222` when it's done booting.

## I wanna mess with this

Cool! You're probably gonna wanna call `build_pxe_stick.sh` with a custom
`IGN_PATH`. The default is
`https://raw.githubusercontent.com/mcsaucy/ephemeros/master/ignition.ign`, so
you'll probably want to change that to the URI for your own.
