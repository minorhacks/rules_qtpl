package main

import (
	"fmt"

	"github.com/minorhacks/rules_qtpl/examples/quicktemplate_readme/templates"
)

func main() {
	fmt.Printf("%s\n", templates.Hello("Foo"))
	fmt.Printf("%s\n", templates.Hello("Bar"))
}
