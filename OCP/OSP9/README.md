# ocplab-osp9
Scripts and OpenStack TripleO Heat Templates from Red Hat Telco Lab in RTP for the ETSI plugfest.  3 Controllers, 2 Computes, 3 Red Hat Ceph Storage nodes.

## Author
Dave Cain

## Usage Outline
1. Clone this repo `git clone https://github.com/novacain1/rhosp-templates/OCP/OSP9` and move all files into the `/home/stack` directory.
2. Install Red Hat OSP-Director using provided `undercloud.conf`.  Modify if necessary.
3. Import and Introspect hardware with provided `~/rhtelco.json` to force static assignment of nodes to specific hardware profiles.
4. Modify `~/templates` to suit your respective environment:
   * Update `network-environment.yaml` and `nic-configs/*` for your respective network configuration in your environment.  Very important!
   * *Be aware that `post-allnodes.yaml` wipes all non-root disks presented to the Director node in preparation to use them as Red Hat Ceph Storage OSDs and Journals.  Don't use systems with data on them that you care about, else it will be lost!*
5. Deploy Red Hat OpenStack Platform with `deployOSP.sh` after sourcing the `stackrc` file as the `stack` user.
6. Enable Fencing on the Controller nodes via `./~/postdeploy-automation/configure_fence.sh`.

## Disclaimer
I work for Red Hat but this repo _by itself_ is not officially supported.
