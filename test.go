package main

import (
	"fmt"
)

func main() {
	// var goods = runtime.GOOS
	// fmt.Printf("The operating system is: %s\n", goods)
	// path := os.Getenv("PATH")
	// fmt.Printf("Path is %s\n", path)
	ch := make(chan int)
	// go f1(ch)
	ch <- 2
	go f1(ch)
	// go sendData(ch)
	// go getData(ch)

	// time.Sleep(10 * 1e9)
}

// func sendData(ch chan int) {
// 	ch <- 1
// 	ch <- 2
// 	ch <- 3
// }

// func getData(ch chan int) {
// 	for {
// 		input := <-ch
// 		fmt.Printf("%d\n", input)
// 	}
// }

func f1(ch chan int) {
	fmt.Printf("%d\n", <-ch)
}
