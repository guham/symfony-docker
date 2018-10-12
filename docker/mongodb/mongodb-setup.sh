#!/bin/bash
set -e

mongo <<EOF
use $MONGO_INITDB_DATABASE
db.createUser({
  user: "$MONGODB_USERNAME",
  pwd: "$MONGODB_PASSWORD",
  roles: [{
    role: "dbOwner",
    db: "$MONGO_INITDB_DATABASE"
  }]
})
use test
db.createUser({
  user: "$MONGODB_USERNAME",
  pwd: "$MONGODB_PASSWORD",
  roles: [{
    role: "dbOwner",
    db: "test"
  }]
})
EOF
