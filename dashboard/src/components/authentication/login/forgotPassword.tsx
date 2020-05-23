import React, { useState, useEffect } from 'react';
import TextField from '@material-ui/core/TextField';
import { createStyles, makeStyles, Theme } from '@material-ui/core/styles';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import CardActions from '@material-ui/core/CardActions';
import Button from '@material-ui/core/Button';
import CardHeader from '@material-ui/core/CardHeader';
import Navbar from '../../common/navbar/navbar';
import Footer from '../../common/footer/footer';
import { FormattedMessage } from 'react-intl';

const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    container: {
      display: 'flex',
      flexWrap: 'wrap',
      width: 400,
      margin: `${theme.spacing(0)} auto`
    },
    submitBtn: {
      marginTop: theme.spacing(2),
      flexGrow: 1,
      background: '#24292e',
      color: '#fff'
    },
    header: {
      textAlign: 'center',
      background: '#24292e',
      color: '#fff'
    },
    card: {
      marginTop: theme.spacing(10)
    }

  }),
);

const ForgotPassword = () => {
  const classes = useStyles();
  const [email, setEmail] = useState('');
  const [isButtonDisabled, setIsButtonDisabled] = useState(true);
  const [helperText, setHelperText] = useState('');
  const [error, setError] = useState(false);

  const navigation = {
    brand: { name: 'Environment Platform', to: '/' },
    links: [
      { name: 'Home', to: '/' },
      { name: 'Login', to: '/' },
      { name: 'Signup', to: '/' },
    ]
  };

  useEffect(() => {
    if (email.trim()) {
      setIsButtonDisabled(false);
    } else {
      setIsButtonDisabled(true);
    }
  }, [email]);

  const handleForgotPassword = () => {
    // TODO - Handle validation
    if (email === 'john@smith.com') {
      setError(false);
      setHelperText('An email will be sent to your email address.');
    } else {
      setError(true);
      setHelperText('Please enter a valid email address.');
    }
  };

  const handleKeyPress = (e:any) => {
    if (e.keyCode === 13 || e.which === 13) {
      isButtonDisabled || handleForgotPassword();
    }
  };

  const { brand, links } = navigation;

  return (
    <>
      <Navbar brand={brand} links={links} />
      <React.Fragment>
        <form className={classes.container} noValidate autoComplete="off">
          <Card className={classes.card}>
            <CardHeader className={classes.header} title="Password Recovery" />
            <CardContent>
              <div>
                <FormattedMessage
                            id='Forgot.Password.Email.Label'
                            defaultMessage='Please enter your email. If your account exists, 
                            we will send you a mail with instructions to recover your password'
                />
                <TextField
                  error={error}
                  fullWidth
                  id="Email"
                  type="email"
                  label="Email"
                  placeholder="Email"
                  margin="normal"
                  onChange={(e)=>setEmail(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                  helperText={helperText}
                />
              </div>
            </CardContent>
            <CardActions>
              <Button
                variant="contained"
                size="large"
                className={classes.submitBtn}
                onClick={()=>handleForgotPassword()}
                disabled={isButtonDisabled}>
                Submit
              </Button>
            </CardActions>
          </Card>
        </form>
        <Footer />
      </React.Fragment>
    </>
  );
}

export default ForgotPassword;
