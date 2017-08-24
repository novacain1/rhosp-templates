# sepialab-osp11
Scripts and OpenStack TripleO Heat Templates from Red Hat Sepia Lab using OSP11 and Composable roles.  3 Controllers, 5 Storage, and 9 Compute nodes.

## Author
Dave Cain

## Network Diagram
TBD.

## Usage Outline
1. Clone this repo `git clone https://github.com/novacain1/rhosp-templates/SEPIA/OSP11` and move all files into the `/home/stack` directory.
2. Install Red Hat OSP-Director using provided `undercloud.conf`.  Modify if necessary.
3. Import and Introspect hardware with provided `~/sepia.json` to force static assignment of nodes to specific hardware profiles.
4. Modify `~/templates` to suit your respective environment:
   * Update `network-environment.yaml` and `nic-configs/*` for your respective network configuration in your environment.  Very important!
5.   * Update `refarch.yaml` for generic Hiera and parameter overrides (including bridge configuration) that should be customized in your respective environment.
6.   * Update `ips-from-pool-all.yaml` should you need to statically assign ipv4 addresses on networks to have the same assignment each deployment.  If you do not need this ability, remove the `-e` from the `deployOSP.sh` script.
7.   * *Be aware that `wipe-disks.yaml` wipes all non-root disks presented to the Director node in preparation to use them as Red Hat Ceph Storage OSDs and Journals.  Don't use systems with data on them that you care about, else it will be lost!*
8. Deploy Red Hat OpenStack Platform with `deployOSP.sh` after sourcing the `stackrc` file as the `stack` user.
9. Enable Fencing on the Controller nodes via `./~/postdeploy-automation/agent_fencing.sh root calvin enable`.
10. Use the `~/postdeploy-automation/postdeploy.sh` to do the following:
   * TBD.
   
## Disclaimer
I work for Red Hat but this repo _by itself_ is not officially supported.
