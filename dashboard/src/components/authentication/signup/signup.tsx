import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import TextField from '@material-ui/core/TextField';
import { createStyles, makeStyles, Theme } from '@material-ui/core/styles';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import CardActions from '@material-ui/core/CardActions';
import Button from '@material-ui/core/Button';
import CardHeader from '@material-ui/core/CardHeader';
import Footer from '../../common/footer/footer';

const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    container: {
      display: 'flex',
      flexWrap: 'wrap',
      width: 400,
      margin: `${theme.spacing(0)} auto`
    },
    signupBtn: {
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
    },

  }),
);

const Signup = () => {
  const classes = useStyles();
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isButtonDisabled, setIsButtonDisabled] = useState(true);
  const [helperText, setHelperText] = useState('');
  const [error, setError] = useState(false);

  useEffect(() => {
    if (displayName.trim() && email.trim() && password.trim() && confirmPassword.trim()) {
      setIsButtonDisabled(false);
    } else {
      setIsButtonDisabled(true);
    }
  }, [displayName, email, password, confirmPassword]);

  const handleSignup = () => {
    // TODO - Handle Signup validation
    if (password === confirmPassword) {
      setError(false);
      setHelperText('Signup Successful... Welcome ' + displayName + '!');
    } else {
      setError(true);
      setHelperText('The passwords do not match.')
    }
  };

  const handleKeyPress = (e:any) => {
    if (e.keyCode === 13 || e.which === 13) {
      isButtonDisabled || handleSignup();
    }
  };

  return (
    <>
      <React.Fragment>
        <form className={classes.container} noValidate autoComplete="off">
          <Card className={classes.card}>
            <CardHeader className={classes.header} title="Sign up" />
            <CardContent>
              <div>
              <TextField
                  error={error}
                  fullWidth
                  id="displayName"
                  type="text"
                  label="Display Name"
                  placeholder="Display Name"
                  margin="normal"
                  onChange={(e)=>setDisplayName(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                />
                <TextField
                  error={error}
                  fullWidth
                  id="email"
                  type="email"
                  label="Email"
                  placeholder="Email"
                  margin="normal"
                  onChange={(e)=>setEmail(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                />
                <TextField
                  error={error}
                  fullWidth
                  id="password"
                  type="password"
                  label="Password"
                  placeholder="Password"
                  margin="normal"
                  onChange={(e)=>setPassword(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                />
                <TextField
                  error={error}
                  fullWidth
                  id="confirmPassword"
                  type="password"
                  label="Confirm Password"
                  placeholder="Confirm Password"
                  margin="normal"
                  helperText={helperText}
                  onChange={(e)=>setConfirmPassword(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                />
                <Link
                  to='/login'
                >
                  Already have an account?
                </Link>
              </div>
            </CardContent>
            <CardActions>
              <Button
                variant="contained"
                size="large"
                className={classes.signupBtn}
                onClick={()=>handleSignup()}
                disabled={isButtonDisabled}>
                Signup
              </Button>
            </CardActions>
          </Card>
        </form>
        <Footer />
      </React.Fragment>
    </>
  );
}

export default Signup;
