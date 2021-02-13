# prometheus-node-exporter-lua-swconfig

This package adds a collector for the prometheus-node-exporter-lua.
The collector returns data for switches configured with the swconfig utility.

## Metrics

```
node_swconfig_port_rxgoodbyte_total
node_swconfig_port_txbyte_total
node_swconfig_port_link_up
node_swconfig_port_link_speed
node_swconfig_vlan_untagged
node_swconfig_vlan_tagged
node_swconfig_port_arltable_entry
```

## Tested with

Support for untested models will most likely not work without changes because the data structure might be different.

- TPLink archer C7 (Atheros AR8337)
