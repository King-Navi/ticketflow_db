Table Credential {
  idCredential int [pk, increment]
  nickname varchar(100) [not null, unique]
  passwordHash varchar(255) [not null]
  role varchar(50) [not null]
}

Table Attendee {
  idAttendee int [pk, increment]
  email varchar(100) [not null]
  firstName varchar(100) [not null]
  lastName varchar(100) [not null]
  middleName varchar(100)
  isActive BOOLEAN
  isEmailVerified BOOLEAN 
  createdAt TIMESTAMP
  updatedAt TIMESTAMP
  lastLogin TIMESTAMP
  idCredential int [not null]
}

Table Organizer {
  idOrganizer int [pk, increment]
  email varchar(100) [not null]
  firstName varchar(100) [not null]
  lastName varchar(100) [not null]
  middleName varchar(100)
  createdAt TIMESTAMP
  updatedAt TIMESTAMP
  lastLogin TIMESTAMP
  isActive BOOLEAN
  idCompany int
  idCredential int [not null]
}

Table Reservation {
  idReservation int [pk, increment]
  expiration TIMESTAMP [not null]
  startDate TIMESTAMP [not null]
  idAttendee int [not null]
  idEventSeat int [not null]
}

Table PaymentMethod {
  idPaymentMethod int [pk, increment]
  
  idAttendee int [not null]
}
Table Card {
  idCard int [pk, increment]
  cvv int [not null]
  expirationDate DATE [not null]
  cardHolderName varchar(100) [not null]
  cardNumber varchar(100) [not null]
  idPaymentMethod int [not null]
}
Table Cryto {
  idCrypto int [pk, increment]
  idPaymentMethod int [not null]
  hash varchar(300) [not null]
}

Table Payment {
  idPayment int [pk, increment]
  purchaseDate DATE [not null]
  taxPercentage int [not null]
  ticketQuantity int [not null]
  idPaymentMethod int [not null]
  idReservation int
}

Table Refund {
  idRefund int [pk, increment]
  refundDate TIMESTAMP [not null]
  reason varchar(100) [not null]
  idTicket int [unique]
  idRefundStatus int [not null]
}

Table RefundStatus {
  idRefundStatus int [pk, increment]
  statusName varchar(100) [not null]
}

Table Ticket {
  idTicket int [pk, increment]
  categoryLabel varchar(100) [not null]
  seatLabel varchar(100) [not null]
  unitPrice int [not null]
  qrCode binary [not null]
  idPayment int [not null]
  idTicketStatus int [not null]
}
Table TicketStatus{
  idTicketStatus int [pk, increment]
  statusName varchar(100) [not null]
}

Table EventLocation {
  idEventLocation int [pk, increment]
  venueName varchar(150) [not null]
  addressLine1 varchar(200) [not null]
  addressLine2 varchar(200)
  city varchar(100) [not null]
  state varchar(100)
  country varchar(100) [not null]
  postalCode varchar(20)
  capacity int
}



Table Section{
  idSection int [pk, increment]
  sectionName varchar(100) [not null]
  idEventLocation int [not null]
}

Table Seat {
  idSeat int [pk, increment]
  seatNo varchar(100) [not null]
  rowNo varchar(100) [not null]
  idSection int  [not null]
}

Table EventSeat {
  idEventSeat int [pk, increment]
  idEvent int [not null, unique]
  idSeat int [not null, unique]
  basePrice decimal(10,2) [not null]
  isBlocked boolean [not null, default: false]
  idTicket int [null]
}


Table Event {
  idEvent int [pk, increment]
  category varchar(100) [not null]
  description varchar(500) [not null]
  date DATE [not null]
  startTime timestamp [not null]
  endTime timestamp  [not null]
  name varchar(100) [not null]
  idCompany int [not null]
}

Table Company {
  idCompany int [pk, increment]
  companyName varchar(100) [not null]
  taxId varchar(100) [not null]
}

Ref: "Company"."idCompany" < "Organizer"."idCompany"
Ref: "Company"."idCompany" < "Event"."idCompany"
Ref: "Ticket"."idTicket" - "Refund"."idTicket"
Ref: "Payment"."idPayment" < "Ticket"."idPayment"
Ref: "PaymentMethod"."idPaymentMethod" < "Payment"."idPaymentMethod"
Ref: "Attendee"."idAttendee" < "PaymentMethod"."idAttendee"
Ref: "Attendee"."idAttendee" < "Reservation"."idAttendee"


Ref: "Credential"."idCredential" - "Attendee"."idCredential"

Ref: "Credential"."idCredential" - "Organizer"."idCredential"


Ref: "Seat"."idSection" > "Section"."idSection"

Ref: "EventLocation"."idEventLocation" < "Section"."idEventLocation"


Ref: "TicketStatus"."idTicketStatus" < "Ticket"."idTicketStatus"

Ref: "RefundStatus"."idRefundStatus" < "Refund"."idRefundStatus"


Ref: "Card"."idPaymentMethod" - "PaymentMethod"."idPaymentMethod"

Ref: "PaymentMethod"."idPaymentMethod" - "Cryto"."idPaymentMethod"

Ref: "EventSeat"."idEvent" > "Event"."idEvent"


Ref: "EventSeat"."idSeat" > "Seat"."idSeat"

Ref: "Reservation"."idEventSeat" > "EventSeat"."idEventSeat"

Ref: "Ticket"."idTicket" - "EventSeat"."idTicket"