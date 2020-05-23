import React from 'react';
import Navbar from '../../common/navbar/navbar';
import Footer from '../../common/footer/footer';

const Portal = () => {

  // TODO - Move this list to a central location
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
      { name: 'My Account', to: '/' }
    ]
  };

  const { brand, links } = navigation;

  return (
    <>
      <Navbar brand={brand} links={links} />
      <React.Fragment>
        // TODO - After discussion
        <Footer />
      </React.Fragment>
    </>
  );
}

export default Portal;