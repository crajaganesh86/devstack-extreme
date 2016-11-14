# http://docs.openstack.org/developer/devstack/plugins.html

mode="$1"
phase="$2"

if [ "$mode" = "stack" -a "$phase" = "pre-install" ]; then
    :
elif [ "$mode" = "stack" -a "$phase" = "install" ]; then
    :

elif [ "$mode" = "stack" -a "$phase" = "post-config" ]; then
    :

elif [ "$mode" = "stack" -a "$phase" = "extra" ]; then

    neutron device-create \
        --name "$EXTREME_SWITCH_NAME" \
        --device_type TOR_SWITCH \
        --vendor extreme \
        --model "$EXTREME_MODEL" \
        --firmware-version "$EXTREME_FIRMWARE_VERSION" \
        --management-ip-address "$EXTREME_MGMT_IP" \
        --user-name "$EXTREME_MGMT_USER" \
        --password "$EXTREME_MGMT_PASSWORD" \
        --vr_total "$EXTREME_VR_TOTAL" \
        ##

    # This part will run when we would like to create a multihost Ericsson
    # devstack, otherwise the traffic will not working between the two
    # devstack nodes.
    if [ "$EXTREME_DEPLOYMENT_TYPE" == "multi-emulated" ]; then
        # Tell neutron about the switch ports.
        neutron deviceport-create "$EXTREME_SWITCH_NAME" \
            --name "${EXTREME_SWITCH_NAME}_port1" \
            --port-id 1 \
            --is-master true \
            --physical-network default \
            ##

        neutron deviceport-create "$EXTREME_SWITCH_NAME" \
            --name "${EXTREME_SWITCH_NAME}_port2" \
            --port-id 2 \
            --is-master true \
            --physical-network default \
            ##

        # Tell neutron about hosts and their functionality.
        neutron host-create \
            --name "$HOST_ALL_IN_ONE" \
            --compute-host \
            --network-host \
            ##

        neutron host-create \
            --name "$HOST_COMPUTE" \
            --compute-host \
            ##

        # Tell the relation between the physical switch ports and hosts to
        # neutron.
        neutron deviceport-addlink \
            "${EXTREME_SWITCH_NAME}_port1" "$HOST_ALL_IN_ONE"
        neutron deviceport-addlink \
            "${EXTREME_SWITCH_NAME}_port2" "$HOST_COMPUTE"
    fi

    # This step is necessary, because the initial network creation originally
    # happens before the topology DB is initialized.
    # If devstack-extreme plugin is enabled it will disable the original
    # network initialization and it will create the necessary networks after
    # the topology DB is ready.
    if [ "$NEUTRON_CREATE_INITIAL_NETWORKS_SAVED" == "True" ]; then
        create_neutron_initial_network
    fi

    if [ "$EXTREME_ENABLE_L3" == "True" ]; then
        # Create public network and subnet
        # In Ericsson we decided to replace router-gateway-set with
        # router-interface-add. Since the meaning of router:external=True
        # is that you can pass the network to router-gateway-set we no longer
        # need it and set it to false.
        EXT_NET_ID=$( neutron net-create "$PUBLIC_NETWORK_NAME" -- \
                      --router:external=False | grep ' id ' | get_field 2 )
        _neutron_create_public_subnet_v4 $EXT_NET_ID

        # Create router
        ROUTER_ID=$( neutron router-create $Q_ROUTER_NAME \
                     | grep ' id ' | get_field 2)
        die_if_not_set $LINENO ROUTER_ID "Can't create router: $Q_ROUTER_NAME"

        # Connect the private and the public network to the router
        neutron router-interface-add "${ROUTER_ID}" "${PUBLIC_SUBNET_NAME}"
        neutron router-interface-add "${ROUTER_ID}" "${PRIVATE_SUBNET_NAME}"
        ROUTER_GW_IP=$( neutron port-list -c fixed_ips -c device_owner \
                        | grep vrrp_control | awk -F '"' '{ print $8 }' )
        die_if_not_set $LINENO ROUTER_GW_IP "Failure retrieving ROUTER_GW_IP"
    fi
fi

if [ "$mode" = "unstack" ]; then
    :

fi

if [ "$mode" = "clean" ]; then
    :

fi
