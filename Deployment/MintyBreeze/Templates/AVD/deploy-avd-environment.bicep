//Define WVD deployment parameters
param hostpoolName string
param hostpoolFriendlyName string
param appgroupName string
param appgroupNameFriendlyName string
param workspaceName string
param workspaceNameFriendlyName string
param preferredAppGroupType string
param avdlocation string 


@description('What is the hostpool type, pooled or personal')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string

@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string 

//Create AVD Hostpool
resource hp 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: hostpoolName
  location: avdlocation
  properties: {
    friendlyName: hostpoolFriendlyName
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: preferredAppGroupType
  }
}

@allowed([
  'Desktop'
  'RemoteApp'
])
param applicationgrouptype string

//Create AVD AppGroup
resource ag 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: appgroupName
  location: avdlocation
  properties: {
    friendlyName: appgroupNameFriendlyName
    applicationGroupType: applicationgrouptype
    hostPoolArmPath: hp.id
  }
}

//Create AVD Workspace
resource ws 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: workspaceName
  location: avdlocation
  properties: {
    friendlyName: workspaceNameFriendlyName
    applicationGroupReferences: [
      ag.id
    ]
  }
}
