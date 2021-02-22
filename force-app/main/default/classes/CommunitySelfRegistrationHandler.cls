global without sharing class CommunitySelfRegistrationHandler implements Auth.ConfigurableSelfRegHandler {
    private final Long CURRENT_TIME = Datetime.now().getTime();
	private final String[] UPPERCASE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
	private final String[] LOWERCASE_CHARS = 'abcdefghijklmnopqrstuvwxyz'.split('');
	private final String[] NUMBER_CHARS = '1234567890'.split('');
	private final String[] SPECIAL_CHARS = '!#$%-_=+<>'.split('');

	global Id createUser(Id accountId, Id profileId, Map<SObjectField, String> registrationAttributes, String password) {
		User user = new User();
		
		for (SObjectField field : registrationAttributes.keySet()) {
			String value = registrationAttributes.get(field);
			user.put(field, value);
		}

        String email = user.Email;
        System.debug(email);
		
		List<User> users = getUsers(email);

		if (users.isEmpty() == false) {
			//generate exception
			//show message - you already have an account
		}

		List<Contact> contacts = getContacts(email);

		if (contacts.isEmpty() == false) {
			//generate exception
			//show message - contact redcross support
		}

        user = generateUser(user, contacts[0], profileId);
        System.debug(user);
		
		insert user;

		password = generateRandomPassword();
		Site.validatePassword(user, password, password);
		System.setPassword(user.Id, password);

		return user.Id;
	}

	private List<Contact> getContacts(String email) {
		return [
			SELECT Id, FirstName, LastName, Email, AccountId
			FROM Contact 
			WHERE Email = :email
			LIMIT 1
		];
	}

	private List<User> getUsers(String email) {
		return [
			SELECT Id
			FROM User
			WHERE Email = :email
			LIMIT 1
		];
	}

	private User generateUser(User user, Contact contact, Id profileId) {
		user.LastName = contact.LastName;
		user.FirstName = contact.FirstName;
		user.Email = contact.Email;
		user.Alias = contact.FirstName.substring(0, 1).toLowerCase() + contact.LastName.substring(0, 3).toLowerCase();
		user.CommunityNickname = contact.FirstName + ' ' + contact.LastName;
		user.ContactId = contact.Id;
		user.UserName = contact.Email + generateRandomInt(1000);
		user.languagelocalekey = UserInfo.getLocale();
		user.localesidkey = UserInfo.getLocale();
		user.emailEncodingKey = 'UTF-8';
		user.timeZoneSidKey = UserInfo.getTimezone().getID();
		user.ProfileId = profileId;

		return user;
	}

	private String generateRandomPassword() {
		String[] characters = new List<String>(UPPERCASE_CHARS);
		characters.addAll(LOWERCASE_CHARS);
		characters.addAll(NUMBER_CHARS);
		characters.addAll(SPECIAL_CHARS);
		String newPassword = '';
		Boolean needsUpper = true, needsLower = true, needsNumber = true, needsSpecial = true;
		while (newPassword.length() < 50) {
			Integer randomInt = generateRandomInt(characters.size());
			String c = characters[randomInt];
			if (needsUpper && c.isAllUpperCase()) {
				needsUpper = false;
			} else if (needsLower && c.isAllLowerCase()) {
				needsLower = false;
			} else if (needsNumber && c.isNumeric()) {
				needsNumber = false;
			} else if (needsSpecial && !c.isAlphanumeric()) {
				needsSpecial = false;
			}
			newPassword += c; 
		}
		newPassword = addMissingPasswordRequirements(newPassword, needsLower, needsUpper, needsNumber, needsSpecial);
		return newPassword;
	}

	private String addMissingPasswordRequirements(String password, Boolean addLowerCase, Boolean addUpperCase, Boolean addNumber, Boolean addSpecial) {
		if (addLowerCase) {
			password += LOWERCASE_CHARS[generateRandomInt(LOWERCASE_CHARS.size())];
		}
		if (addUpperCase) {
			password += UPPERCASE_CHARS[generateRandomInt(UPPERCASE_CHARS.size())];
		}
		if (addNumber) {
			password += NUMBER_CHARS[generateRandomInt(NUMBER_CHARS.size())];
		}
		if (addSpecial) {
			password += SPECIAL_CHARS[generateRandomInt(SPECIAL_CHARS.size())];
		}
		return password;
	}

	// Generates a random number from 0 up to, but not including, max.
	private Integer generateRandomInt(Integer max) {
		return Math.mod(Math.abs(Crypto.getRandomInteger()), max);
	}

	// Default implementation to try to provide uniqueness
	private String generateAlias() {
		String timeString = String.valueOf(CURRENT_TIME);
		return timeString.substring(timeString.length() - 8);
	}
}
