package main

import (
	"flag"
	"fmt"
	"net/smtp"
	"time"

	email "github.com/jordan-wright/email"
)

func main() {
	var addr string
	flag.StringVar(&addr, "addr", "", "email addressi (To:)")
	var subject string
	flag.StringVar(&subject, "subject", "MongoDB backup cron failure", "email subject")
	var from string
	flag.StringVar(&from, "from", "MongoDB cron <root@localhost>", "email from field")
	var password string
	flag.StringVar(&password, "password", "", "password for email account")
	var smtpHost string
	flag.StringVar(&smtpHost, "smtpHost", "smtp.gmail.com", "smtp host name")
	var smtpPort int
	flag.IntVar(&smtpPort, "smtpPort", 587, "smtp port number")
	flag.Parse()
	e := email.NewEmail()
	e.From = from
	e.To = []string{addr}
	e.Subject = "MongoDB backup cron failure"
	text := fmt.Sprintf("MongoDB backup cron failure at %v", time.Now())
	e.Text = []byte(text)
	smtpHostPort := fmt.Sprintf("%s:%d", smtpHost, smtpPort)
	e.Send(smtpHostPort, smtp.PlainAuth("", from, password, smtpHost))
}
