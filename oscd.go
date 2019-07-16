/*********************************************
 * (C) Intel Corp 2019
 * Fabian Salamanca fabian.salamanca@intel.com
 *********************************************/
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
	"os"
	"os/user"
	"strings"
	"text/template"

	"github.com/alexflint/go-arg"
)

// ParsedNet for passing values to template
type ParsedNet struct {
	Iface       string
	IPAddress   string
	Netmask     string
	Gateway     string
	Nameservers []string
}

func handleErr(err error) {
	if err != nil {
		panic(err)
	}
}

func writeToFile(filename, data string) {
	dat := []byte(data)
	err := ioutil.WriteFile(filename, dat, 0644)
	handleErr(err)
}

func readJSONFile(path string) string {
	file, err := os.Open(path)
	handleErr(err)

	defer file.Close()
	scanner := bufio.NewScanner(file)
	b := ""
	for scanner.Scan() {
		b = b + scanner.Text()
	}
	return (b)
}

func metaConfig(mfile string) {
	var mymeta Meta
	metajson := readJSONFile(mfile)
	bmetajson := []byte(metajson)
	err := json.Unmarshal(bmetajson, &mymeta)
	handleErr(err)
	writeToFile("hostname", mymeta.Hostname+"\n")
	var thekeys string
	for _, akey := range mymeta.Keys {
		thekeys = thekeys + akey.Data
	}
	writeToFile("authorized_keys", thekeys)
}

func writeNetConfig(nfile string, nics []string) {
	var mynet Network
	var parsed ParsedNet
	netfile := "60-oscd.network"
	templ := template.Must(template.ParseFiles(netfile + ".templ"))
	file, err := os.Create(netfile)
	handleErr(err)
	fmt.Println()
	netjson := readJSONFile(nfile)
	bnetjson := []byte(netjson)
	err = json.Unmarshal(bnetjson, &mynet)
	handleErr(err)
	for i, nic := range nics {
		parsed.Iface = nic
		parsed.Gateway = mynet.Networks[i].Routes[i].Gateway
		parsed.IPAddress = mynet.Networks[i].IPAddress
		stringMask := net.IPMask(net.ParseIP(mynet.Networks[i].Netmask).To4())
		length, _ := stringMask.Size()
		parsed.Netmask = string(length)
		for _, ns := range mynet.Services {
			parsed.Nameservers = append(parsed.Nameservers, ns.Address)
		}
		err = templ.ExecuteTemplate(file, netfile+".templ", parsed)
		handleErr(err)
	}
	fmt.Println(mynet)
	fmt.Println("Updating hostname")
}

func cluser(username string) {
	myuser, err := user.Lookup(username)
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(myuser)
}

func main() {
	var args struct {
		Nics    string `arg:"required"`
		Meta    string `arg:"required"`
		Network string `arg:"required"`
	}
	arg.MustParse(&args)
	nics := strings.Split(args.Nics, ",")
	writeNetConfig(args.Network, nics)
	metaConfig(args.Meta)
	cluser("clear")
}
