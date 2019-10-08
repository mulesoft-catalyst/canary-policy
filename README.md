# Canary Policy
A Mule policy that allows a gateway proxy to support a canary release strategy by dynamically changing the API Implementation host.

# A note on API versioning
This policy has been designed to modify the host an API is routed to. For example instead of going to `v1.microservice.mycompany.com` it will send the request to `v2.microservice.mycompany.com`. This versioning strategy may not be appropriate for all use cases, in which case this policy can be modified to support URI based versioning.

# Canary release strategy

Canary release is a technique to reduce the risk of introducing a new software version in production by slowly rolling out the change to a small subset of users before rolling it out to the entire infrastructure and making it available to everybody. Further reading on canary releasing can be found on Martin Fowlers website [here](https://martinfowler.com/bliki/CanaryRelease.html)

The canary release begins by deploying the new service into production with no users routed to the service. When this has been tested and validated, the next step is to begin routing traffic to the new service.

There are many strategies to routing the traffic, and this is where an API Proxy running on a Mulesoft gateway comes in. The consumer (client) calls the Gateway, and then the proxy forwards the request to the implementation. By using a policy the canary approach can be implemented via the Gateway.

The policy has been designed to be as flexible as possible rather than dictating how the routing strategy should be executed. By exposing the conditions as MEL fields, the users of the policy can dictate when to trigger the routing.

The following are examples of approaches that can be taken with the policy:

1. Route based on a header presence
2. Route based on a percentage of weighting
3. Route based on a clientID
4. Route based on an IP range (to support internal staff pilots)

A benefit of a canary release is when a certain confidence is achieved in the new service the traffic level routing to the new service can be increased. By using a policy this can be changed without having to deploy any code changes, but via a policy update.

# Policy Configuration

The policy requires four properties to be set which determine the behavior.

## Mel expressions

### Original service MEL expression
This property is the MEL expression that captures when a particular request should be sent to the original service.

For example if you want to route based on the value of a header it would be:
***
`#[message.inboundProperties.'X-CanaryHeader'=='Release1']`
***

### New service MEL expression
This property is the MEL expression that captures when a particular request should be sent to the newly deployed service.

For example if you want to route based on the value of a header it would be:
***
`#[message.inboundProperties.'X-CanaryHeader'=='Release2']`
***

## Host values

### Original Host
The hostname of the original microservice

### New Host
The hostname of the new microservice


# Proxy changes to use the policy

For this policy to work the Proxy artifact generated by the Mulesoft API Manager must be modified. The change required is in the `config.properties` file in the downloaded zip. The change required is modifying the implementation.host property to be a MEL expression pointing to a flow variable with a ternary expression to keep the default host as the one specified in the API configuration.

The following script automatically performs this change:
```
zipedit(){

    curdir=$(pwd)
    unzip "$1" "$2" -d /tmp
    cd /tmp
    sed -i'.original' "s/\(implementation.host=\)\(.*\)/\1#[flowVars.host != null ? flowVars.host : '\2']/"  "/tmp/$2" && zip --update -y "$curdir/$1"  "$2"
    rm -f "$2"
    cd "$curdir"
}

zipedit your-downloaded-prozy-zip.3.9.x.zip classes/config.properties
```

`config.properties` before the script has run:
```
api.name=test-proxy
api.version=1
proxy.port=8081
proxy.path=/hello-world/*
proxy.responseTimeout=25000
implementation.host=v1.microservice.mycompany.com
implementation.port=8081
implementation.path=/test

```

`config.properties` after the script has run:
```
api.name=test-proxy
api.version=1
proxy.port=8081
proxy.path=/hello-world/*
proxy.responseTimeout=25000
implementation.host=#[flowVars.host != null ? flowVars.host : 'v1.microservice.mycompany.com']
implementation.port=8081
implementation.path=/test

```

If you need to support URI based canary routing, the MEL expression could be changed to the implementation.path property
