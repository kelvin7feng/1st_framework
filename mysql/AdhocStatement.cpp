#include "AdhocStatement.h"
#include "DatabaseException.h"

#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string>
#include <cwchar>
#include <locale>

using namespace std;

namespace MySQLWrap {

AdhocStatement::AdhocStatement(MySQLClient &db, const string &sqlStatement) : _db(db) {
	_currentColumn = 0;
	_numberResultColumns = 0;
	_numberAffectedRows = 0;
	_numberResultRows = 0;
	_numberParams = 0;

	_resultWasStored = false;
	_eof = true;

	StoreSqlStatement(sqlStatement);
	Prepare();
}

AdhocStatement::AdhocStatement(const AdhocStatement &stmt) : _db(stmt._db) {
	_sqlStatement = stmt._sqlStatement;
	_currentColumn = 0;
	_numberResultColumns = 0;
	_numberAffectedRows = 0;
	_numberResultRows = 0;
	_numberParams = stmt._numberParams;

	_resultWasStored = false;
	_eof = true;

	Prepare();
}

AdhocStatement::~AdhocStatement() {
	if (_result != NULL) {
		mysql_free_result(_result);
	}

	_result = NULL;
	_numberResultColumns = 0;
	_numberAffectedRows = 0;
	_numberResultRows = 0;
	
	_resultWasStored = false;
	_eof = true;

	ResetParameters();
}

void AdhocStatement::StoreSqlStatement(const std::string &sqlStatement) {
	wchar_t dest[sqlStatement.length() + 1];
	memset(dest, 0, sizeof(dest));
	size_t charsWritten = mbstowcs(dest, sqlStatement.c_str(), sqlStatement.length());
	_sqlStatement = std::wstring(dest, charsWritten);
}

void AdhocStatement::ScanForInsertions() {
	wchar_t insideQuote = L'\0';
	for (size_t i = 0; i < _sqlStatement.length(); i++) {
		wchar_t it = _sqlStatement[i];
		if ((it == L'\'') || (it == L'"')) {
			if (insideQuote == it) {
				insideQuote = L'\0';
			} else if (insideQuote == L'\0') {
				insideQuote = it;
			}
		}
		if (it == L'?') {
			if (insideQuote == L'\0') {
				 _numberParams += 1;
			}
		}
	}
}

unsigned long AdhocStatement::ParameterCount() {
	return _numberParams;
}

unsigned long AdhocStatement::RemainingParameters() {
	return _numberParams - _params.size();	
}

void AdhocStatement::Prepare() {
	if (! _db.IsConnected()) {
		throw DatabaseException("AdhocStatement::Prepare", 0, "----", "Database is not connected");
	}
	_result = NULL;
	ScanForInsertions();
}

std::string AdhocStatement::ReplaceInsertions() {
	std::stringstream result;
	char buff[sizeof(wchar_t)];
	unsigned int bufflen;
	wchar_t insideQuote = L'\0';
	unsigned int paramCount = 0;

	for (auto it = _sqlStatement.begin(); it != _sqlStatement.end(); it++) {
		if ((*it == L'\'') || (*it == L'"')) {
			if (insideQuote == *it) {
				insideQuote = L'\0';
			} else if (insideQuote == L'\0') {
				insideQuote = *it;
			}
			bufflen = wctomb(buff, *it);
			result.write(buff, bufflen);
		}
		else if ((*it == L'?') && (insideQuote == L'\0')) {
			if (paramCount < _params.size())
			{
				std::string s = _params[paramCount]->Get();
				result.write(s.data(), s.length());
				paramCount++;
			} else {
				throw DatabaseException("Error in AdhocStatement::ReplaceInsertions", 0, "----", "unexpected insertion points");
			}
		} else {
			bufflen = wctomb(buff, *it);
			result.write(buff, bufflen);
		}
	}		
	return result.str();
}

void AdhocStatement::Execute() {
	if (! _db.IsConnected()) {
		throw DatabaseException("Error in AdhocStatement::Execute", 0, "----", "Database is not connected");
	}

	if (RemainingParameters() != 0) {
		throw DatabaseException("Error in AdhocStatement::Execute", 0, "----", "There are stil some unsatisfied parameters");
	}

	std::string sql = ReplaceInsertions();
	if (mysql_real_query(_db._db, sql.data(), sql.length()) != 0) {
		throw DatabaseException(_db._db, "Error in AdhocStatement::Prepare");
	}

	_numberResultColumns = mysql_field_count(_db._db);
	_result = mysql_store_result(_db._db);
	
	if (_result == NULL && _numberResultColumns > 0) {
		throw DatabaseException(_db._db, "Error in AdhocStatement::Execute");
	} 

	_resultWasStored = true;

	if (_numberResultColumns == 0) {
		_eof = true;
		_numberAffectedRows = mysql_affected_rows(_db._db);
	} else {
		_eof = false;
		_numberResultRows = mysql_num_rows(_result);
		_fields = mysql_fetch_fields(_result);
		if (_fields == NULL) {
			throw DatabaseException("Error in AdhocStatement::Execute", 0, "----", "couldn't retrieve fields from query");
		}
	}
}

void AdhocStatement::ResetParameters() {
	while (! _params.empty()) {
		AdhocParameter *buf = _params.back();
		_params.pop_back();
		delete buf;
	}	
}

void AdhocStatement::AssignNextParameter(const Nullable<std::string> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<char> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<unsigned char> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<short int> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<unsigned short int> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<int> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<unsigned int> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<Julian> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<Binary> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<float> &param) {
	AssignNextParameterTemplate(param);
}

void AdhocStatement::AssignNextParameter(const Nullable<double> &param) {
	AssignNextParameterTemplate(param);
}


void AdhocStatement::AssignNextParameter(AdhocParameter *buffer) {
	if (buffer == NULL) { 
		throw DatabaseException("Error in AdhocStatement::AssignNextParameter", 0, "----", "Buffer cannot be null");
	}

	if (RemainingParameters() == 0) {
		delete buffer;
		throw DatabaseException("Error in AdhocStatement::AssignNextParameter", 0, "----", "Have already assigned all possible input parameters");
	}

	_params.push_back(buffer);
}

bool AdhocStatement::FetchNextRow() {
	_currentRow = mysql_fetch_row(_result);	
	if (_currentRow == NULL) {
		_eof = true;
		return false;
	}

	_currentRowLengths = mysql_fetch_lengths(_result);	
	if (_currentRowLengths == NULL) {
		throw DatabaseException("Error in AdhocStatement::Fetch", 0, "----", "fetch lengths returned NULL");
	}

	return true;
}

bool AdhocStatement::Eof() { 
	return _eof;
}

unsigned long long AdhocStatement::NumberOfAffectedRows() { 
	return _numberAffectedRows;
}

unsigned long long AdhocStatement::NumberOfReturnedRows() {
	return _numberResultRows;
}

AdhocStatement::operator bool() {
	return ! Eof();
}


Nullable<char> AdhocStatement::GetTinyDataInRow(unsigned int column) {
	Nullable<char> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_TINY) || ((_fields[column].flags & UNSIGNED_FLAG) != 0)) {
			throw DatabaseException("Error in AdhocStatement.GetTinyDataInRow", 0, "----", "database field is not an signed tiny type");
		}
		char ival = (char) 0;
		if (sscanf(val->c_str(), "%hhi",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetTinyDataInRow", 0, "----", "sscanf failed to produce a char.");
		}
		result = ival;
	}
	return result;
}

Nullable<unsigned char> AdhocStatement::GetUTinyDataInRow(unsigned int column) {
	Nullable<unsigned char> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_TINY) || ((_fields[column].flags & UNSIGNED_FLAG) == 0)) {
			throw DatabaseException("Error in AdhocStatement.GetUTinyDataInRow", 0, "----", "database field is not an unsigned tiny type");
		}
		unsigned char ival = (unsigned char) 0;
		if (sscanf(val->c_str(), "%hhui",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetUTinyDataInRow", 0, "----", "sscanf failed to produce an unsigned char");
		}
		result = ival;
	}
	return result;
}

Nullable<short int> AdhocStatement::GetShortDataInRow(unsigned int column) {
	Nullable<short int> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_SHORT) || ((_fields[column].flags & UNSIGNED_FLAG) != 0)) {
			throw DatabaseException("Error in AdhocStatement.GetShortDataInRow", 0, "----", "database field is not a signed short type");
		}
		short int ival = (short int) 0;
		if (sscanf(val->c_str(), "%hi",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetUShortDataInRow", 0, "----", "sscanf failed to produce an unsigned short");
		}
		result = ival;
	}
	return result;
}

Nullable<unsigned short int> AdhocStatement::GetUShortDataInRow(unsigned int column) {
	Nullable<unsigned short int> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_YEAR) && ((_fields[column].type != MYSQL_TYPE_SHORT) || ((_fields[column].flags & UNSIGNED_FLAG) == 0))) {
			throw DatabaseException("Error in AdhocStatement.GetUShortDataInRow", 0, "----", "database field is not a unsigned short or year type");
		}
		unsigned short int ival = (unsigned short int) 0;
		if (sscanf(val->c_str(), "%hui",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetUShortDataInRow", 0, "----", "sscanf failed to produce an unsigned short");
		}
		result = ival;
	}
	return result;
}

Nullable<int> AdhocStatement::GetLongDataInRow(unsigned int column) {
	Nullable<int> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_LONG) || ((_fields[column].flags & UNSIGNED_FLAG) != 0)) {
			throw DatabaseException("Error in AdhocStatement.GetLongDataInRow", 0, "----", "database field is not a signed int type");
		}
		int ival = (short int) 0;
		if (sscanf(val->c_str(), "%i",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetLongDataInRow", 0, "----", "sscanf failed to produce an integer");
		}
		result = ival;
	}
	return result;
}

Nullable<unsigned int> AdhocStatement::GetULongDataInRow(unsigned int column) {
	Nullable<unsigned int> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_LONG) || ((_fields[column].flags & UNSIGNED_FLAG) == 0)) {
			throw DatabaseException("Error in AdhocStatement.GetULongDataInRow", 0, "----", "database field is not an unsigned int type");
		}
		unsigned int ival = (unsigned int) 0;
		if (sscanf(val->c_str(), "%ui",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetLongDataInRow", 0, "----", "sscanf failed to produce an unsigned integer");
		}
		result = ival;
	}
	return result;
}

Nullable<float> AdhocStatement::GetFloatDataInRow(unsigned int column) {
	Nullable<float> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if (_fields[column].type != MYSQL_TYPE_FLOAT) {
			throw DatabaseException("Error in AdhocStatement.GetFloatDataInRow", 0, "----", "database field is not a float type");
		}
		float ival = (float) 0;
		if (sscanf(val->c_str(), "%f",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetLongDataInRow", 0, "----", "sscanf failed to produce a float");
		}
		result = ival;
	}
	return result;
}

Nullable<double> AdhocStatement::GetDoubleDataInRow(unsigned int column) {
	Nullable<double> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if (_fields[column].type != MYSQL_TYPE_DOUBLE) {
			throw DatabaseException("Error in AdhocStatement.GetDoubleDataInRow", 0, "----", "database field is not a double type");
		}
		double ival = (double) 0;
		if (sscanf(val->c_str(), "%lf",  &ival) != 1) {
			throw DatabaseException("Error in AdhocStatement::GetLongDataInRow", 0, "----", "sscanf failed to produce a double");
		}
		result = ival;
	}
	return result;
}

Nullable<string> AdhocStatement::GetStringDataInRow(unsigned int column) {
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_VAR_STRING) && 
		    (_fields[column].type != MYSQL_TYPE_STRING) &&
		    (_fields[column].type != MYSQL_TYPE_DECIMAL) &&
		    (_fields[column].type != MYSQL_TYPE_BIT) &&
		    (_fields[column].type != MYSQL_TYPE_VARCHAR)) {
			throw DatabaseException("Error in AdhocStatement::GeStringDataInRow", 0, "----", "database field is not a string, decimal, bit, or varchar type");
		}
	}
	return val;
}

Nullable<string> AdhocStatement::GetStringDataInRowInternal(unsigned int column) {
	Nullable<string> result;
	if (column >= _numberResultColumns) { 
		throw DatabaseException("Error in AdhocStatement::GetStringDataInRowInternal", 0, "----", "column requested outside of range of result set");
	}

	if (_currentRow[column] != NULL) {
		result = string(_currentRow[column], _currentRowLengths[column]);
	}

	return result;
}

Nullable<Binary> AdhocStatement::GetBinaryDataInRow(unsigned int column) {
	Nullable<Binary> result;
	if (column >= _numberResultColumns) { 
		throw DatabaseException("Error in AdhocStatement::GetBinaryDataInRow", 0, "----", "column requested outside of range of result set");
	}

	if ((_fields[column].type != MYSQL_TYPE_BLOB) &&
	    (_fields[column].type != MYSQL_TYPE_TINY_BLOB) &&
	    (_fields[column].type != MYSQL_TYPE_MEDIUM_BLOB) &&
	    (_fields[column].type != MYSQL_TYPE_LONG_BLOB)) {
		throw DatabaseException("Error in AdhocStatement::GetBinaryDataInRow", 0, "----", "value is not a blob type");
	}
	if (_currentRow[column] != NULL) {
		Binary b1;
		b1.AssignDataToBuffer((unsigned char *)_currentRow[column], _currentRowLengths[column]);
		result = b1;
	}

	return result;
}

Nullable<Julian> AdhocStatement::GetTimeDataInRow(unsigned int column) {
	Nullable<Julian> result;
	Nullable<string> val = GetStringDataInRowInternal(column);
	if (val.HasValue()) {
		if ((_fields[column].type != MYSQL_TYPE_TIMESTAMP) &&
		    (_fields[column].type != MYSQL_TYPE_DATE) &&
		    (_fields[column].type != MYSQL_TYPE_TIME) &&
		    (_fields[column].type != MYSQL_TYPE_DATETIME)) {
			throw DatabaseException("Error in AdhocStatement::GetTimeDataInRow", 0, "----", "value is not a date or time type");
		}

		MYSQL_TIME timeval;
		timeval.year = 0;
		timeval.month = 0;
		timeval.day = 0;
		timeval.hour = 0;
		timeval.minute = 0;
		timeval.second = 0;
		timeval.second_part = 0;

		timeval.time_type = MYSQL_TIMESTAMP_NONE;

		if (val.deref().find("-") != std::string::npos) {
			int res = sscanf(val->c_str(), "%u-%u-%u %u:%u:%u.%lu",  &timeval.year, &timeval.month, &timeval.day, 
					&timeval.hour, &timeval.minute, &timeval.second, &timeval.second_part);
			if (res == 3) {
				timeval.time_type = MYSQL_TIMESTAMP_DATE;
			} else if (res >= 6) {
				timeval.time_type = MYSQL_TIMESTAMP_DATETIME;
			} else {
				throw DatabaseException("Error in AdhocStatement::GetUShortDataInRow", 0, "----", "sscanf failed to produce a valid time value");
			}
		} else if (val.deref().find(":") != std::string::npos) {
			int res = sscanf(val->c_str(), "%u:%u:%u.%lu",  &timeval.hour, &timeval.minute, &timeval.second, &timeval.second_part);
			if (res >= 3) {
				timeval.time_type = MYSQL_TIMESTAMP_TIME;
			} else {
				throw DatabaseException("Error in AdhocStatement::GetUShortDataInRow", 0, "----", "sscanf failed to produce a valid time value");
			}
		}

		GregorianBreakdown gb(timeval, 0);
		result = Julian(gb);
	}
	return result;
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<string> &result) {
	result = GetStringDataInRowInternal(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<char> &result) {
	result = GetTinyDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<unsigned char> &result) {
	result = GetUTinyDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<short int> &result) {
	result = GetShortDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<unsigned short int> &result) {
	result = GetUShortDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<int> &result) {
	result = GetLongDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<unsigned int> &result) {
	result = GetULongDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<Julian> &result) {
	result = GetTimeDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<float> &result) {
	result = GetFloatDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<double> &result) {
	result = GetDoubleDataInRow(column);
}

void AdhocStatement::GetDataInRow(unsigned int column, Nullable<Binary> &result) {
	result = GetBinaryDataInRow(column);
}

unsigned int AdhocStatement::GetNextDataColumn() {
	unsigned int result = _currentColumn;
	_currentColumn++;
	return result;
}

}
