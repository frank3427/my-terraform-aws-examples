# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
}

output Instructions {
  value = <<EOF

---- DocumentDB cluster details
Endpoint: ${aws_docdb_cluster.demo26.endpoint}
Por     : ${var.docdb_port}
User    : ${var.docdb_user}
Password: ${local.docdb_pwd}

---- You can SSH directly to the Linux instance with MongoDB Client by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo26_al2.public_ip}

---- Once connected to the Linux instance, you can connect to the DocumentDB cluster / MongoDB database using the following script:
./docdb.sh

Notes:

- you can list the existing databases the following command:
      show dbs

- you can create a new database and switch to it with the following command:
      use db1

- you can insert documents using the following command:
      db.movies.insertMany([
      {
            title: "Jurassic World: Fallen Kingdom",
            genres: [ "Action", "Sci-Fi" ],
            runtime: 130,
            rated: "PG-13",
            year: 2018,
            directors: [ "J. A. Bayona" ],
            cast: [ "Chris Pratt", "Bryce Dallas Howard", "Rafe Spall" ],
            type: "movie"
      },
      {
            title: "Tag",
            genres: [ "Comedy", "Action" ],
            runtime: 105,
            rated: "R",
            year: 2018,
            directors: [ "Jeff Tomsic" ],
            cast: [ "Annabelle Wallis", "Jeremy Renner", "Jon Hamm" ],
            type: "movie"
      }
      ])

- you can look for a specific document using following command:
      db.movies.find( { title: "Tag" } )

- you can list all documents using following command:
      db.movies.find()

- More examples at https://www.mongodb.com/docs/mongodb-shell/crud/

EOF
}