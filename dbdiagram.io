Table Credential {
  idCredential int [pk, increment]
  email varchar(100) [not null]
  nickname varchar(100) [not null, unique]
  passwordHash varchar(255) [not null]
  isActive BOOLEAN
  isEmailVerified BOOLEAN 
  createdAt TIMESTAMP
  updatedAt TIMESTAMP
  lastLogin TIMESTAMP
  role varchar(50) [not null]
}

Table Attendee {
  idAttendee int [pk, increment]
  firstName varchar(100) [not null]
  lastName varchar(100) [not null]
  middleName varchar(100)
  idCredential int [not null]
}

Table Organizer {
  idOrganizer int [pk, increment]
  firstName varchar(100) [not null]
  lastName varchar(100) [not null]
  middleName varchar(100)
  idCompany int
  idCredential int [not null]
}

Table Reservation {
  idReservation int [pk, increment]
  expirationAt TIMESTAMP [not null]
  createdAt TIMESTAMP [not null]
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
Table Crypto {
  idCrypto int [pk, increment]
  idPaymentMethod int [not null]
  hash varchar(300) [not null]
}

Table Payment {
  idPayment int [pk, increment]
  purchaseAt TIMESTAMP [not null]
  taxPercentage int [not null]
  ticketQuantity int [not null]
  idPaymentMethod int [not null]
  idReservation int
}

Table Refund {
  idRefund int [pk, increment]
  refundDate TIMESTAMP [not null]
  reason varchar(500) [not null]
  refundAmount decimal(10,2)
  idTicket int [not null, unique]
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
  unitPrice decimal(10,2) [not null]
  checkedInAt timestamp
  qrCode binary [not null]
  idPayment int [not null]
  idTicketStatus int [not null]
  idEventSeat int [not null]
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
  idEvent int [not null]
  idSeat int [not null]
  basePrice decimal(10,2) [not null]
  idEventSeatStatus int [not null]
}
Table EventSeatStatus{
  idEventSeatStatus int [pk, increment]
  eventSeatStatusName varchar(100)
}

Table Event {
  idEvent int [pk, increment]
  category varchar(100) [not null]
  description varchar(500) [not null]
  eventDate DATE [not null]
  startTime TIME [not null]
  endTime TIME  [not null]
  eventName varchar(100) [not null]
  idCompany int [not null]
  idEventLocation int [not null]
}
Table EventStatus {
  idEventStatus int [pk, increment]
}

Table EventImage {
  idEventImage      int [pk, increment]
  idEvent           int [not null]
  idEventImageType  int [not null]
  imagePath         varchar(300) [not null]
  sortOrder         int
  createdAt         timestamp
  updatedAt         timestamp
}

Table EventImageType {
  idEventImageType int [pk, increment]
  code             varchar(50) [not null, unique]
  description      varchar(150)
  createdAt        timestamp
  updatedAt        timestamp
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

Ref: "PaymentMethod"."idPaymentMethod" - "Crypto"."idPaymentMethod"

Ref: "EventSeat"."idEvent" > "Event"."idEvent"


Ref: "EventSeat"."idSeat" > "Seat"."idSeat"

Ref: "Reservation"."idEventSeat" > "EventSeat"."idEventSeat"



Ref: "Ticket"."idEventSeat" > "EventSeat"."idEventSeat"

Ref: "Event"."idEventLocation" > "EventLocation"."idEventLocation"

Ref: "EventSeatStatus"."idEventSeatStatus" < "EventSeat"."idEventSeatStatus"

Ref: "EventImage"."idEvent" > "Event"."idEvent"

Ref: "EventImageType"."idEventImageType" < "EventImage"."idEventImageType"