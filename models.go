/*********************************************
 *
 * (C) 2019
 * Fabian Salamanca - fabian@nuo.com.mx
 *
 *********************************************/


package main

// Network for unmarshalling
type Network struct {
	Services []Services `json:"services"`
	Networks []Networks `json:"networks"`
}

// Services for unmarshalling
type Services struct {
	Type    string `json:"type"`
	Address string `json:"address"`
}

// Networks for unmarshalling
type Networks struct {
	Type      string   `json:"type"`
	Netmask   string   `json:"netmask"`
	IPAddress string   `json:"ip_address"`
	Routes    []Routes `json:"routes"`
	ID        string   `json:"id"`
}

// Routes for unmarshalling
type Routes struct {
	Netmask string `json:"netmask"`
	Network string `json:"network"`
	Gateway string `json:"gateway"`
}

// Keys for
type Keys struct {
	Data string `json:"data"`
}

// Meta from CD
type Meta struct {
	Hostname string `json:"hostname"`
	Keys     []Keys `json:"keys"`
}
