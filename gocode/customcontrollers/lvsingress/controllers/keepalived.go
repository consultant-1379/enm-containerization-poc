package controllers

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"text/template"

	//	ctrl "sigs.k8s.io/controller-runtime"
	"syscall"

	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

//Keepalived object
type Keepalived struct {
	ExtIface  string
	IntIface  string
	ExtIP     string
	IntIP     string
	Priority  int
	Vips      []string
	ExtIPPeer string
	//Using only 1 value for internalIP peer for conntrackd
	IntIPPeer  string
	Vrid       int
	Configured bool
	NodeLabel  map[string]string
	Tmpl       *template.Template
	cmd        *exec.Cmd
}

var keepalivedTmpl = "keepalived.tmpl"
var conntrackdTmpl = "conntrackd.tmpl"

const (
	keepalivedConfig = "/etc/keepalived/keepalived.conf"
	conntrackdConfig = "/etc/conntrackd/conntrackd.conf"
)

//WriteKeepalivedConf config for keepalived
func (k *Keepalived) WriteKeepalivedConf() error {
	w, err := os.Create(keepalivedConfig)
	if err != nil {
		return err
	}

	defer w.Close()

	conf := make(map[string]interface{})
	conf["iface"] = k.ExtIface
	conf["ip"] = k.ExtIP
	conf["vips"] = k.Vips
	conf["peerIP"] = k.ExtIPPeer
	conf["vrid"] = k.Vrid
	k.loadTemplate(keepalivedTmpl)
	println("writing keepalived conf ===========================")
	return k.Tmpl.Execute(w, conf)
}

//WriteConntrackdConf config for keepalived
func (k *Keepalived) WriteConntrackdConf() error {
	w, err := os.Create(conntrackdConfig)
	if err != nil {
		return err
	}

	defer w.Close()

	conf := make(map[string]interface{})
	conf["intIface"] = k.IntIface
	conf["intIP"] = k.IntIP
	conf["extIP"] = k.ExtIP
	conf["peerIP"] = k.IntIPPeer

	k.loadTemplate(conntrackdTmpl)
	println("writing conntrackd conf ===========================")
	return k.Tmpl.Execute(w, conf)
}

//StartKeepalived
func (k *Keepalived) StartKeepalived() error {
	k.cmd = exec.Command("keepalived", "--dont-fork", "--release-vips",
		"--pid", "/keepalived.pid")

	if err := k.cmd.Run(); err != nil {
		fmt.Println("keepalived start command failed error", err)
		return err
	}
	fmt.Println("keepalived started")
	return nil
}

//StartConntrackd
func (k *Keepalived) StartConntrackd() error {
	cmd := exec.Command("conntrackd")

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	cmd.Stdout = &stdout
	if err := cmd.Run(); err != nil {
		fmt.Println("conntrackd start command failed error", stderr.String())
		return err
	}
	fmt.Println("conntrackd started", stdout.String())
	return nil
}

//Stop stop keepalived process
func (k *Keepalived) Stop() error {
	//remove vips...
	fmt.Println("sending SIG to keepalived")
	if err := syscall.Kill(k.cmd.Process.Pid, syscall.SIGTERM); err != nil {
		fmt.Println("FAILED to stop keepalived")
		return err
	}
	return nil
}

//Reload reload keepalived process
func (k *Keepalived) Reload() {

}

//Start starts keepalived and conntrackd
func (k *Keepalived) Start() error {
	kerr := k.StartKeepalived()
	if kerr != nil {
		return kerr
	}

	cerr := k.StartConntrackd()
	if cerr != nil {
		return cerr
	}
	return nil
}

//RemoveVIP doesnt remove vip...so should issue command to remove vip from interface
func (k *Keepalived) RemoveVIP(vip string) error {

	cmd := exec.Command("ip", "addr", "del", vip, "dev", k.ExtIface)

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	cmd.Stdout = &stdout
	if err := cmd.Run(); err != nil {
		fmt.Println("removingvip failed", stderr.String())
		return err
	}
	fmt.Println("removed vip", stdout.String())
	return nil

}

//
// changeSysctl changes the required network setting in /proc to get
// keepalived working in the local system.
// func changeSysctl() error {
// 	// sysctl changes required by keepalived
// 	sysctlAdjustments := map[string]int{
// 		// allows processes to bind() to non-local IP addresses
// 		"net/ipv4/ip_nonlocal_bind": 1,
// 		// enable connection tracking for LVS connections
// 		"net/ipv4/vs/conntrack": 1,
// 	}
// 	sys := sysctl.New()
// 	for k, v := range sysctlAdjustments {
// 		if err := sys.SetSysctl(k, v); err != nil {
// 			return err
// 		}
// 	}

// 	return nil
// }

//GetIP ip of the controller instance
func (k *Keepalived) GetIP(c client.Client) error {

	// should come from env...nodeslector as well
	k.IntIP = os.Getenv("NODE_INTERNAL_IP")

	//Get node
	nodeName := os.Getenv("NODE_NAME")

	node := &corev1.Node{}

	err := c.Get(context.Background(), client.ObjectKey{
		Name: nodeName,
	}, node)
	if err != nil {
		return ignoreNotFound(err)
	}
	//k.NodeLabel = pod.Spec.NodeSelector

	// externalIP is on the status fields...its and array!

	for _, address := range node.Status.Addresses {
		if address.Type == "ExternalIP" {
			if address.Address != "" {
				k.ExtIP = address.Address
				break
			}
		}
	}
	return nil
}

//GetPeers peers for keepalived
//only 2 worker nodes supported
func (k *Keepalived) GetPeers(c client.Client) error {
	nodes := &corev1.NodeList{}

	label := make(map[string]string)
	label["type"] = "worker-router"

	if err := c.List(context.Background(), nodes, client.MatchingLabels(label)); err != nil {
		return err
	}

	for _, node := range nodes.Items {
		for _, address := range node.Status.Addresses {
			if address.Type == "ExternalIP" {
				if address.Address != "" && address.Address != k.ExtIP {
					fmt.Println("===============peer found has IP: =========", address.Address)
					k.ExtIPPeer = address.Address
				}
			}
			if address.Type == "InternalIP" {
				if address.Address != "" && address.Address != k.IntIP {
					fmt.Println("===============peer for conntrack found has IP: =========", address.Address)
					k.IntIPPeer = address.Address
				}
			}
		}
	}

	return nil
}

func (k *Keepalived) loadTemplate(tpmlf string) error {
	tmpl, err := template.ParseFiles(tpmlf)
	if err != nil {
		fmt.Println("failed to load template", err)
		return err
	}
	k.Tmpl = tmpl
	return nil
}

func (k *Keepalived) getIface() error {
	// get interface to use from system
	//cmd := ""

	k.ExtIface = "eth1"
	k.IntIface = "eth0"
	return nil
}

func (k *Keepalived) ConfigureKeepalived(c client.Client) error {

	//changeSysctl()
	k.GetIP(c)
	k.getIface()
	k.GetPeers(c)
	k.Vrid = 103
	cmVip := os.Getenv("CM_VIP")
	fmVip := os.Getenv("FM_VIP")
	k.Vips = []string{cmVip, fmVip}

	if err := k.WriteKeepalivedConf(); err != nil {
		fmt.Println("==============error writing keepalived conf ====================", err)
		return err
	}

	if err := k.WriteConntrackdConf(); err != nil {
		fmt.Println("=============error writing conntrackd conf ====================", err)
		return err
	}

	k.Configured = true

	//k.Stop()

	return nil
}

func (k *Keepalived) appendIP(slice []string, vip string) []string {
	for _, ip := range slice {
		if ip == vip {
			return slice
		}
	}
	return append(slice, vip)
}

func (k *Keepalived) HandleSigterm() {
	signalChan := make(chan os.Signal, 1)
	done := make(chan bool, 1)

	fmt.Println("Setting up sigterm keepalived channel")
	signal.Notify(signalChan, syscall.SIGTERM)
	fmt.Println("Turning on Listener channel")

	go func() {
		<-signalChan
		fmt.Println("Received SIGTERM, shutting down")

		fmt.Println("sending SIG to keepalived")
		if err := syscall.Kill(k.cmd.Process.Pid, syscall.SIGTERM); err != nil {
			fmt.Println("FAILED to stop keepalived")

		}

		for _, vip := range k.Vips {
			fmt.Println("trying to remove vip ", vip)
			k.RemoveVIP(vip)
		}
		done <- true
	}()

}
