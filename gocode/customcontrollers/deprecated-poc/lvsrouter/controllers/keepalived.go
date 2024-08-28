package main

import (
	"os"
)

var keepalivedTmpl = "keepalived.tmpl"

type keepalived struct {
	iface    string
	ip       string
	priority int
	vrid     int
}

func (K *keepalived) writeConfig(vips []string) error {
	w, err := os.Create(keepalivedConfig)
	if err != nil {
		return err
	}

	defer w.Close()

}
