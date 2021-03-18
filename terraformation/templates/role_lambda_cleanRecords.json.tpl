{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ExampleStmt",
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Principal":{
        "Service": [
          "s3.amazonaws.com"
        ]
      }
    }
  ]
}