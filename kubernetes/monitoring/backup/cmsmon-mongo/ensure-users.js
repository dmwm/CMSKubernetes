const targetDbStr = 'test';
const rootUser = process.env["$MONGO_ROOT_USERNAME"];
const rootPass = process.env["MONGO_ROOT_PASSWORD"];
const usersStr = process.env["MONGO_USERS_LIST"];

const adminDb = db.getSiblingDB('admin');
adminDb.auth(rootUser, rootPass);
print('Successfully authenticated admin user');

const targetDb = db.getSiblingDB(targetDbStr);

const customRoles = adminDb
  .getRoles({rolesInfo: 1, showBuiltinRoles: false})
  .map(role => role.role)
  .filter(Boolean);

usersStr
  .trim()
  .split(';')
  .map(s => s.split(':'))
  .forEach(user => {
    const username = user[0];
    const rolesStr = user[1];
    const password = user[2];

    if (!rolesStr || !password) {
      return;
    }

    const roles = rolesStr.split(',');
    const userDoc = {
      user: username,
      pwd: password,
    };

    userDoc.roles = roles.map(role => {
      if (!~customRoles.indexOf(role)) {
        return role;
      }
      return {role: role, db: 'admin'};
    });

    try {
      targetDb.createUser(userDoc);
    } catch (err) {
      if (!~err.message.toLowerCase().indexOf('duplicate')) {
        throw err;
      }
    }
  });
