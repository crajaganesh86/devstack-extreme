Extreme Plugin for DevStack
===========================

# Synopsis

The 'extreme' mechanism driver of OpenStack Neutron ML2 has a so-called
topology DB, effectively describing wiring between Extreme Networks
switches and OpenStack compute hosts. The Extreme L3 plugin needs some
device (ie. networking device) attributes set very early. This plugin
performs a minimalistic initialization for all Extreme neutron plugins
and drivers, so they can be started, tested and maintained in devstack.

# Configuration

Put this into your devstack's local.conf:

[[local|localrc]]

enable_service neutron

enable_plugin q-extreme ssh://gerrit.ericsson.se:29418/cee/openstack/devstack-extreme master

Q_PLUGIN=ml2
Q_ML2_PLUGIN_TYPE_DRIVERS=vlan
Q_ML2_PLUGIN_MECHANISM_DRIVERS=openvswitch,extreme,baremetal
Q_ML2_TENANT_NETWORK_TYPE=vlan

EXTREME_MGMT_IP="192.168.200.20"
EXTREME_MGMT_USER="devstack"
EXTREME_MGMT_PASSWORD="devstack"

# Extreme deployment type
# This variable will be ignored when the extreme plugin is not loaded
# There are two possible options now
# single-mocked - This option means that you have an all-in-one
# devstack with mocked extreme.
# multi-emulated - This option means that you have a multi host devstack
# (an all-in-one host + a compute node) with an extreme emulator.
EXTREME_DEPLOYMENT_TYPE=single-mocked

# Topology DB
# You need to specify the hostnames of both of your hosts if you have set
# EXTREME_DEPLOYMENT_TYPE to multi-emulated. Otherwise these variables will
# be ignored.
HOST_ALL_IN_ONE="devstack"
HOST_COMPUTE="compute"

# Extreme L3: Do not enable q-l3 (that is the l3-agent) and Extreme L3
# together because they are incompatible.
EXTREME_ENABLE_L3=True


[[post-config|$NEUTRON_CONF]]

[DEFAULT]
# Load the topology extension.
api_extensions_path = "$NEUTRON_DIR/neutron/ericsson/extensions"
service_plugins = neutron.ericsson.services.l3_router.ml3.plugin.Ml3Plugin,neutron.ericsson.db.topology_db.TopologyDbPlugin

[ml3]
l3_providers = extreme:default,l3_agent

[[post-config|/$Q_PLUGIN_CONF_FILE]]

[extreme]
driver = neutron.ericsson.drivers.extreme.log.ExtremeLogManager
#driver = neutron.ericsson.drivers.extreme.soap.manager.ExtremeSoapManager
start_periodic_checker = False
