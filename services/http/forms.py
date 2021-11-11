from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, BooleanField
from wtforms.validators import DataRequired, Length, Email, EqualTo, ValidationError
import sqlite3


class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    remember = BooleanField('Remember Me')
    submit = SubmitField('Login')


def validate_email(self, email):
    conn = sqlite3.connect('login.db')
    curs = conn.cursor()
    curs.execute("SELECT email FROM login where email = (?)", [email.data])
    valemail = curs.fetchone()
    if valemail is None:
        raise ValidationError('This Email ID is not registered. Please register before login')
