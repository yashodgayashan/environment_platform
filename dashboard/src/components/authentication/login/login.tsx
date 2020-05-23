import React, { useState, useEffect } from 'react';
import TextField from '@material-ui/core/TextField';
import { createStyles, makeStyles, Theme } from '@material-ui/core/styles';
import Card from '@material-ui/core/Card';
import CardContent from '@material-ui/core/CardContent';
import CardActions from '@material-ui/core/CardActions';
import Button from '@material-ui/core/Button';
import CardHeader from '@material-ui/core/CardHeader';
import Link from '@material-ui/core/Link';
import Navbar from '../../common/navbar/navbar';
import Footer from '../../common/footer/footer';

const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    container: {
      display: 'flex',
      flexWrap: 'wrap',
      width: 400,
      margin: `${theme.spacing(0)} auto`
    },
    loginBtn: {
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

const Login = () => {
  const classes = useStyles();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [isButtonDisabled, setIsButtonDisabled] = useState(true);
  const [helperText, setHelperText] = useState('');
  const [error, setError] = useState(false);

  const navigation = {
    brand: { name: 'Environment Platform', to: '/' },
    links: [
      { name: 'Home', to: '/' },
      { name: 'Item 2', to: '/' },
      { name: 'Item 3', to: '/' },
      { name: 'Item 4', to: '/' },
      { name: 'Item 5', to: '/' },
      { name: 'Item 6', to: '/' },
      { name: 'Item 7', to: '/' },
      { name: 'Item 8', to: '/' },
      { name: 'Item 9', to: '/' },
      { name: 'Item 10', to: '/' }
    ]
  };

  useEffect(() => {
    if (username.trim() && password.trim()) {
      setIsButtonDisabled(false);
    } else {
      setIsButtonDisabled(true);
    }
  }, [username, password]);

  const handleLogin = () => {
    // TODO - Handle login validation
    if (username === 'john@smith.com' && password === 'password') {
      setError(false);
      setHelperText('Login Successful');
    } else {
      setError(true);
      setHelperText('Incorrect username or password')
    }
  };

  const handleKeyPress = (e:any) => {
    if (e.keyCode === 13 || e.which === 13) {
      isButtonDisabled || handleLogin();
    }
  };

  const { brand, links } = navigation;

  return (
    <>
      <Navbar brand={brand} links={links} />
      <React.Fragment>
        <form className={classes.container} noValidate autoComplete="off">
          <Card className={classes.card}>
            <CardHeader className={classes.header} title="Environment Platform" />
            <CardContent>
              <div>
                <TextField
                  error={error}
                  fullWidth
                  id="username"
                  type="email"
                  label="Username"
                  placeholder="Username"
                  margin="normal"
                  onChange={(e)=>setUsername(e.target.value)}
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
                  helperText={helperText}
                  onChange={(e)=>setPassword(e.target.value)}
                  onKeyPress={(e)=>handleKeyPress(e)}
                />
                <Link
                  component="button"
                  variant="body2"
                  // onClick={() => {}}
                >
                  Forgot Password?
                </Link>
              </div>
            </CardContent>
            <CardActions>
              <Button
                variant="contained"
                size="large"
                className={classes.loginBtn}
                onClick={()=>handleLogin()}
                disabled={isButtonDisabled}>
                Login
              </Button>
            </CardActions>
          </Card>
        </form>
        <Footer />
      </React.Fragment>
    </>
  );
}

export default Login;